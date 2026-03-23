import SwiftUI
import RealityKit
import ARKit
import Combine
import AudioToolbox

extension SIMD4 {
    var xyz: SIMD3<Scalar> { SIMD3(x, y, z) }
}

struct ARTableView: View {
    @State private var surfaceMessage: String? = nil
    @StateObject private var selectionManager = SelectionManager()
    @StateObject private var connectionManager = ConnectionManager()
    
    @State private var showMicrocontrollerPopup = false
    @State private var selectedMicrocontrollerEntity: String? = nil
    @State private var showMicrocontrollerProgramming = false
    @State private var savedPrograms: [String: [ProgramBlock]] = [:] // MC name -> saved blocks
    
    var body: some View {
        ZStack {
            ARViewContainer(
                selectionManager: selectionManager,
                connectionManager: connectionManager
            )
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                globalSelectionManager = selectionManager
                
                onMicrocontrollerLongPress = { entityName in
                    self.selectedMicrocontrollerEntity = entityName
                    self.showMicrocontrollerPopup = true
                }
            }
            
            if showMicrocontrollerPopup, let mcEntityName = selectedMicrocontrollerEntity {
                let portsInfo = connectionManager.getMicrocontrollerPortsInfo(mcName: mcEntityName)
                let portStates: [Int: Bool] = [
                    1: connectionManager.getMicrocontrollerPortState(mcName: mcEntityName, port: 1),
                    2: connectionManager.getMicrocontrollerPortState(mcName: mcEntityName, port: 2),
                    3: connectionManager.getMicrocontrollerPortState(mcName: mcEntityName, port: 3)
                ]
                
                MicrocontrollerInfoPopup(
                    portsInfo: portsInfo,
                    portStates: portStates,
                    onPortStateChanged: { port, isHigh in
                        connectionManager.setMicrocontrollerPortState(mcName: mcEntityName, port: port, isHigh: isHigh)
                    },
                    onProgramButtonTapped: {
                        showMicrocontrollerPopup = false
                        showMicrocontrollerProgramming = true
                    },
                    onDismiss: {
                        showMicrocontrollerPopup = false
                        selectedMicrocontrollerEntity = nil
                    }
                )
                .zIndex(1000)
            }
            
            if showMicrocontrollerProgramming, let mcEntityName = selectedMicrocontrollerEntity {
                MicrocontrollerProgrammingView(
                    mcEntityName: mcEntityName,
                    connectionManager: connectionManager,
                    initialBlocks: savedPrograms[mcEntityName] ?? [],
                    onMinimize: { blocks in
                        savedPrograms[mcEntityName] = blocks
                        showMicrocontrollerProgramming = false
                    },
                    onClose: { 
                        savedPrograms[mcEntityName] = nil
                        showMicrocontrollerProgramming = false
                        selectedMicrocontrollerEntity = nil
                    }
                )
                .zIndex(1001)
            }
            
            VStack {
                HStack(spacing: 20) {
                    Button("Clear") { clearAllEntities() }
                        .foregroundColor(.red)
                    Button("Add Table") { spawnTable(showMessage: $surfaceMessage) }
                    Button("Microcontroller") { spawnEntity(fileName: "MicrocontrollerM") }
                    Button("Battery") { spawnEntity(fileName: "Battery5") }
                    Button("Bulb") { spawnEntity(fileName: "Bulb") }
                    Button("Wire") { spawnEntity(fileName: "Wire4") }
                    Button("Switch") { spawnEntity(fileName: "switch") }
                    Button("Push Button") { spawnEntity(fileName: "PushB") }
                    Button("Ultrasonic") { spawnEntity(fileName: "Ultrasonic") }
                    Button("Light Sensor") { spawnEntity(fileName: "LightSensor") }
                }
                .padding()
                .background(.black.opacity(0.6))
                .foregroundColor(.white)
                .cornerRadius(12)
                
                Spacer()
                
                if selectionManager.selectedEntity != nil {
                    Text("✓ Selected - Drag or rotate with two fingers")
                        .padding(8)
                        .background(Color.green.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.bottom, 20)
                }
            }
            .padding()
            
            VStack(spacing: 0) {
                Spacer().frame(height: 100) // Top spacing below buttons
                
                HStack {
                    Spacer()
                    VStack(spacing: 20) {
                        if let selectedEntity = selectionManager.selectedEntity {
                            RotationControl(selectedEntity: selectedEntity, bottomPadding: 0)
                        }
                        
                        if let selectedEntity = selectionManager.selectedEntity,
                           let modelChild = selectedEntity.children.first(where: { $0.name != "SelectionHighlight" }) {
                            FloatingDeleteButton(
                                selectedEntity: selectedEntity,
                                topPadding: 0,
                                onDelete: {
                                    let entityName = modelChild.name
                                    deleteEntity(named: entityName, from: tableEntity, connectionManager: connectionManager, selectionManager: selectionManager)
                                }
                            )
                        }
                        
                        if let table = tableEntity {
                            let allWrappers = table.children.filter { $0.name == "DraggableWrapper" }
                            ForEach(Array(allWrappers.enumerated()), id: \.offset) { index, wrapper in
                                if let modelChild = wrapper.children.first(where: { $0.name != "SelectionHighlight" }) {
                                    let cleanedName = connectionManager.cleanName(modelChild.name)
                                    let entityName = modelChild.name
                                    
                                    if cleanedName.contains("LightSensor") {
                                        SensorDisplayView(
                                            title: "LIGHT LEVEL",
                                            reading: connectionManager.lightSensorReadings[entityName] ?? nil,
                                            formatter: { lux in String(format: "%.0f lux", lux) },
                                            activeColor: .yellow,
                                            index: 0
                                        )
                                    }
                                }
                            }
                        }
                        
                        if let table = tableEntity {
                            let allWrappers = table.children.filter { $0.name == "DraggableWrapper" }
                            ForEach(Array(allWrappers.enumerated()), id: \.offset) { index, wrapper in
                                if let modelChild = wrapper.children.first(where: { $0.name != "SelectionHighlight" }) {
                                    let cleanedName = connectionManager.cleanName(modelChild.name)
                                    let entityName = modelChild.name
                                    
                                    if cleanedName.contains("Ultrasonic") {
                                        SensorDisplayView(
                                            title: "DISTANCE",
                                            reading: connectionManager.ultrasonicDistances[entityName] ?? nil,
                                            formatter: { dist in String(format: "%.1f cm", dist * 100) },
                                            activeColor: .cyan,
                                            index: 0
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .padding(.trailing, 20)
                }
                
                Spacer()
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .zIndex(500)
            
            if let message = surfaceMessage {
                Text(message)
                    .padding()
                    .background(Color.red.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .transition(.opacity)
                    .animation(.easeInOut, value: message)
                    .padding(.top, 50)
            }
        }
    }
}

// Selection Manager

class SelectionManager: ObservableObject {
    @Published var selectedEntity: Entity?
    
    func selectEntity(_ entity: Entity) {
        deselectEntity()
        
        selectedEntity = entity
        
        let highlight = ModelEntity(
            mesh: .generateCone(height: 0.04, radius: 0.025),
            materials: [SimpleMaterial(color: .yellow.withAlphaComponent(0.8), isMetallic: false)]
        )
        highlight.name = "SelectionHighlight"
        highlight.position = [0, 0.15, 0]
        highlight.orientation = simd_quatf(angle: .pi, axis: [1, 0, 0])
        
        let bobbingAnimation = FromToByAnimation<Transform>(
            name: "bobbing",
            from: .init(scale: .init(repeating: 1.0), rotation: simd_quatf(angle: .pi, axis: [1, 0, 0]), translation: [0, 0.15, 0]),
            to: .init(scale: .init(repeating: 1.0), rotation: simd_quatf(angle: .pi, axis: [1, 0, 0]), translation: [0, 0.10, 0]),
            duration: 0.8,
            timing: .easeInOut,
            isAdditive: false,
            bindTarget: .transform,
            repeatMode: .autoReverse
        )
        
        if let animationResource = try? AnimationResource.generate(with: bobbingAnimation) {
            highlight.playAnimation(animationResource.repeat())
        }
        
        entity.addChild(highlight)
        
    }
    
    func deselectEntity() {
        guard let selected = selectedEntity else { return }
        
        if let highlight = selected.findEntity(named: "SelectionHighlight") {
            highlight.removeFromParent()
        }
        
        selectedEntity = nil
    }
}

// Connection Manager

class ConnectionManager: ObservableObject {
    @Published var connections: [String] = []
    @Published var isPoweredOn: Bool = false  // For UI debugging
    private let connectionThreshold: Float = 0.04 // Distance in meters (4cm)
    private var connectionGraph: [String: Set<String>] = [:] // entity name -> connected entity names
    private var allEntities: [Entity] = [] // Store reference to all entities
    private var connectedBulbIDs: Set<String> = [] // Track which specific bulbs are in valid circuits
    private var connectedSensorIDs: Set<String> = [] // Track which sensors are in valid circuits (with battery)
    var switchStates: [String: Bool] = [:] // Track switch states: entityName -> isClosed (true = closed/conducting)
    var microcontrollerPortStates: [String: [Int: Bool]] = [:] // MC name -> [port: isHigh], default HIGH
    var pushButtonStates: [String: Bool] = [:] // entityName -> isPressed (true = HIGH/conducting)
    @Published var mcRunningStates: [String: Bool] = [:]  // MC name -> isRunning (persists across view dismissal)
    var mcRunningTasks: [String: Task<Void, Never>] = [:]  // MC name -> running task
    @Published var ultrasonicDistances: [String: Float?] = [:] // entity name -> meters, nil = no surface
    @Published var lightSensorReadings: [String: Float?] = [:] // entity name -> lux, nil = no reading
    private var activePushButtonPorts: [(mcName: String, port: Int)] = [] // ports forced HIGH by push buttons
    
    func checkConnections(entities: [Entity], selectionManager: SelectionManager? = nil) {
        var newConnections: [String] = []
        connectionGraph.removeAll()
        allEntities = entities // Store for later use
        
        
        for (_, wrapper) in entities.enumerated() {
            _ = wrapper.children.first(where: { $0.name != "SelectionHighlight" })
        }
        
        var entitiesWithPorts: [(wrapper: Entity, ports: [Entity], name: String)] = []
        
        for wrapper in entities {
            var allPorts: [Entity] = []
            allPorts.append(contentsOf: findAllEntitiesRecursive(name: "mainPort", in: wrapper))
            allPorts.append(contentsOf: findAllEntitiesRecursive(name: "mainPortP", in: wrapper))
            allPorts.append(contentsOf: findAllEntitiesRecursive(name: "mainPort1", in: wrapper))
            allPorts.append(contentsOf: findAllEntitiesRecursive(name: "mainPort2", in: wrapper))
            allPorts.append(contentsOf: findAllEntitiesRecursive(name: "mainPort3", in: wrapper))
            
            if !allPorts.isEmpty {
                var displayName = "Component"
                if let modelChild = wrapper.children.first(where: { $0.name != "SelectionHighlight" }) {
                    displayName = modelChild.name.isEmpty ? "Component" : modelChild.name
                }
                
                if displayName == "Component" {
                    continue
                }
                
                entitiesWithPorts.append((wrapper, allPorts, displayName))
            }
        }
        
        for i in 0..<entitiesWithPorts.count {
            for j in (i+1)..<entitiesWithPorts.count {
                let entity1 = entitiesWithPorts[i]
                let entity2 = entitiesWithPorts[j]
                
                var hasConnection = false
                var minDistance: Float = Float.infinity
                
                for port1 in entity1.ports {
                    for port2 in entity2.ports {
                        let port1WorldPos = port1.position(relativeTo: nil)
                        let port2WorldPos = port2.position(relativeTo: nil)
                        
                        let distance = simd_distance(port1WorldPos, port2WorldPos)
                        minDistance = min(minDistance, distance)
                        
                        if distance < connectionThreshold {
                            hasConnection = true
                            
                            if let selectionManager = selectionManager {
                                let isEntity1Selected = entity1.wrapper == selectionManager.selectedEntity
                                let isEntity2Selected = entity2.wrapper == selectionManager.selectedEntity
                                
                                if isEntity1Selected && !isEntity2Selected {
                                    let port1WorldPos = port1.position(relativeTo: nil)
                                    let port2WorldPos = port2.position(relativeTo: nil)
                                    let offsetNeeded = port2WorldPos - port1WorldPos
                                    
                                    let wrapperParent = entity1.wrapper.parent!
                                    let localOffset = wrapperParent.convert(direction: offsetNeeded, from: nil)
                                    entity1.wrapper.position = entity1.wrapper.position + localOffset
                                    playSnapSound()
                                } else if isEntity2Selected && !isEntity1Selected {
                                    let port1WorldPos = port1.position(relativeTo: nil)
                                    let port2WorldPos = port2.position(relativeTo: nil)
                                    let offsetNeeded = port1WorldPos - port2WorldPos
                                    
                                    let wrapperParent = entity2.wrapper.parent!
                                    let localOffset = wrapperParent.convert(direction: offsetNeeded, from: nil)
                                    entity2.wrapper.position = entity2.wrapper.position + localOffset
                                    playSnapSound()
                                }
                            }
                            
                            break
                        }
                    }
                    if hasConnection { break }
                }
                
                if !hasConnection {
                }
                
                if hasConnection {
                    if connectionGraph[entity1.name] == nil {
                        connectionGraph[entity1.name] = Set<String>()
                    }
                    if connectionGraph[entity2.name] == nil {
                        connectionGraph[entity2.name] = Set<String>()
                    }
                    connectionGraph[entity1.name]?.insert(entity2.name)
                    connectionGraph[entity2.name]?.insert(entity1.name)
                    
                    let name1 = cleanName(entity1.name)
                    let name2 = cleanName(entity2.name)
                    let connectionString = "\(name1) ↔ \(name2)"
                    if !newConnections.contains(connectionString) {
                        newConnections.append(connectionString)
                    }
                }
            }
        }
        
        let circuitIsValid = hasValidCircuit()
        
        triggerPower()
        
        DispatchQueue.main.async {
            self.connections = newConnections
            self.isPoweredOn = circuitIsValid
        }
    }
    
    private func hasValidCircuit() -> Bool {
        connectedBulbIDs.removeAll()
        connectedSensorIDs.removeAll()
        
        var batteries: [String] = []
        var bulbs: [String] = []
        var sensors: [String] = []
        var microcontrollers: [String] = []
        var wires: [String] = []
        var connectedBulbs: Set<String> = []
        var connectedMicrocontrollers: Set<String> = []
        
        for entityName in connectionGraph.keys {
            let cleanEntityName = cleanName(entityName)
            if cleanEntityName.contains("Battery") {
                batteries.append(entityName)
            } else if cleanEntityName.contains("Bulb") {
                bulbs.append(entityName)
            } else if cleanEntityName.contains("Ultrasonic") || cleanEntityName.contains("LightSensor") {
                sensors.append(entityName)
            } else if cleanEntityName.contains("Microcontroller") {
                microcontrollers.append(entityName)
            } else if cleanEntityName.contains("Wire") {
                wires.append(entityName)
            } else if cleanEntityName.contains("switch") {
                if switchStates[entityName] == nil {
                    switchStates[entityName] = false
                }
            } else if cleanEntityName.contains("PushB") {
                if pushButtonStates[entityName] == nil {
                    pushButtonStates[entityName] = false
                }
            }
        }
        
        guard !batteries.isEmpty else {
            return false
        }
        
        var hasAnyValidCircuit = false
        for battery in batteries {
            for bulb in bulbs {
                if pathExists(from: battery, to: bulb) {
                    connectedBulbs.insert(bulb)
                    hasAnyValidCircuit = true
                }
            }
            
            for mc in microcontrollers {
                if pathExists(from: battery, to: mc) {
                    connectedMicrocontrollers.insert(mc)
                    hasAnyValidCircuit = true  // MC being powered counts as valid circuit
                }
            }
        }
        
        for sensor in sensors {
            for mc in connectedMicrocontrollers {
                if pathExists(from: sensor, to: mc) {
                    connectedSensorIDs.insert(sensor)
                    break
                }
            }
        }
        
        connectedBulbIDs = connectedBulbs
        
        return hasAnyValidCircuit
    }
    
    private func triggerPower() {
        for wrapper in allEntities {
            if let modelChild = wrapper.children.first(where: { $0.name != "SelectionHighlight" }) {
                let entityName = modelChild.name
                if cleanName(entityName).contains("Bulb") {
                    if connectedBulbIDs.contains(entityName) {
                        replaceModel(wrapper: wrapper, originalBulb: modelChild, filename: "BulbM")
                    } else {
                        replaceModel(wrapper: wrapper, originalBulb: modelChild, filename: "Bulb")
                    } 
                }
            }
        }
    }
    
    private func replaceModel(wrapper: Entity, originalBulb: Entity, filename: String) {
        do {
            
            let litBulb = try Entity.load(named: filename)
            
            litBulb.components.remove(CollisionComponent.self)
            litBulb.components.remove(InputTargetComponent.self)
            
            litBulb.transform = originalBulb.transform
            litBulb.name = originalBulb.name // Keep the same name
            
            if filename == "BulbM" {
                let bounds = litBulb.visualBounds(relativeTo: litBulb)
                let maxY = bounds.center.y + (bounds.extents.y / 2)
                let threshold = maxY - (bounds.extents.y * 0.4) // Top 40% of the bulb
                
                func addGlowToMeshes(entity: Entity) {
                    if let modelEntity = entity as? ModelEntity {
                        let entityY = modelEntity.position(relativeTo: litBulb).y
                        
                        if entityY >= threshold {
                            var material = UnlitMaterial()
                            material.color = .init(tint: UIColor(red: 1.0, green: 0.9, blue: 0.0, alpha: 1.0))
                            
                            if let model = modelEntity.model {
                                var newModel = model
                                newModel.materials = [material]
                                modelEntity.model = newModel
                            }
                        }
                    }
                    
                    for child in entity.children {
                        addGlowToMeshes(entity: child)
                    }
                }
                
                addGlowToMeshes(entity: litBulb)
            }
            
            originalBulb.removeFromParent()
            
            wrapper.addChild(litBulb)
            
        } catch {
        }
    }
    
    func toggleSwitch(entityName: String) {
        let currentState = switchStates[entityName] ?? false
        let newState = !currentState
        switchStates[entityName] = newState
        swapSwitchModel(entityName: entityName, isClosed: newState)
        checkConnections(entities: allEntities)
        onSwitchToggleCallback?()
    }
    
    func setPushButtonState(entityName: String, isPressed: Bool) {
        pushButtonStates[entityName] = isPressed
        
        if isPressed {
            forceConnectedMCPortHigh(pushButtonName: entityName)
        } else {
            releaseConnectedMCPort(pushButtonName: entityName)
        }
        
        checkConnections(entities: allEntities)
    }
    
    private func forceConnectedMCPortHigh(pushButtonName: String) {
        guard let pushWrapper = allEntities.first(where: {
            ($0.children.first(where: { $0.name != "SelectionHighlight" }))?.name == pushButtonName
        }), let pushModel = pushWrapper.children.first(where: { $0.name != "SelectionHighlight" }) else { return }
        
        let pushPorts = findAllEntitiesRecursive(name: "mainPort", in: pushModel)
        guard !pushPorts.isEmpty else { return }
        
        for mcWrapper in allEntities {
            guard let mcModel = mcWrapper.children.first(where: { $0.name != "SelectionHighlight" }),
                  cleanName(mcModel.name).contains("Microcontroller") else { continue }
            let mcName = mcModel.name
            
            for portNum in [1, 2, 3] {
                let mcPorts = findAllEntitiesRecursive(name: "mainPort\(portNum)", in: mcModel)
                
                for mcPort in mcPorts {
                    let mcPortWorldPos = mcPort.position(relativeTo: nil)
                    
                    for pushPort in pushPorts {
                        let pushPortWorldPos = pushPort.position(relativeTo: nil)
                        if simd_distance(mcPortWorldPos, pushPortWorldPos) < connectionThreshold {
                            if microcontrollerPortStates[mcName] == nil { microcontrollerPortStates[mcName] = [:] }
                            microcontrollerPortStates[mcName]?[portNum] = true
                            activePushButtonPorts.append((mcName: mcName, port: portNum))
                            return
                        }
                    }
                    
                    if let mcNeighbors = connectionGraph[mcName] {
                        for neighbor in mcNeighbors {
                            guard let neighborWrapper = allEntities.first(where: {
                                ($0.children.first(where: { $0.name != "SelectionHighlight" }))?.name == neighbor
                            }), let neighborModel = neighborWrapper.children.first(where: { $0.name != "SelectionHighlight" }) else { continue }
                            
                            let neighborPorts = findAllEntitiesRecursive(name: "mainPort", in: neighborModel)
                            for neighborPort in neighborPorts {
                                let neighborPortWorldPos = neighborPort.position(relativeTo: nil)
                                if simd_distance(mcPortWorldPos, neighborPortWorldPos) < connectionThreshold {
                                    if pathExistsExcludingMC(from: pushButtonName, to: neighbor, excludingMC: mcName) {
                                        if microcontrollerPortStates[mcName] == nil { microcontrollerPortStates[mcName] = [:] }
                                        microcontrollerPortStates[mcName]?[portNum] = true
                                        activePushButtonPorts.append((mcName: mcName, port: portNum))
                                        return
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func findPortConnectedToward(mcName: String, toward: String) -> Int {
        guard let mcWrapper = allEntities.first(where: {
            ($0.children.first(where: { $0.name != "SelectionHighlight" }))?.name == mcName
        }), let _ = mcWrapper.children.first(where: { $0.name != "SelectionHighlight" }) else { return 0 }
        
        guard let neighbors = connectionGraph[mcName] else { return 0 }
        
        for neighbor in neighbors {
            let portNum = getPortNumberForConnection(mcName: mcName, connectedEntity: neighbor)
            if portNum > 0 { return portNum }
        }
        return 0
    }
    
    private func releaseConnectedMCPort(pushButtonName: String) {
        for entry in activePushButtonPorts {
            if microcontrollerPortStates[entry.mcName] == nil { microcontrollerPortStates[entry.mcName] = [:] }
            microcontrollerPortStates[entry.mcName]?[entry.port] = false
        }
        activePushButtonPorts.removeAll()
    }
    
    func releaseAllPushButtons() {
        let pressedButtons = pushButtonStates.filter { $0.value == true }.map { $0.key }
        for key in pushButtonStates.keys {
            pushButtonStates[key] = false
        }
        if !pressedButtons.isEmpty {
            for name in pressedButtons {
                releaseConnectedMCPort(pushButtonName: name)
            }
            checkConnections(entities: allEntities)
        }
    }
    
    private func swapSwitchModel(entityName: String, isClosed: Bool) {
        for wrapper in allEntities {
            if let modelChild = wrapper.children.first(where: { $0.name != "SelectionHighlight" }) {
                if modelChild.name == entityName {
                    let newModelName = isClosed ? "switchM" : "switch"
                    
                    replaceModel(wrapper: wrapper, originalBulb: modelChild, filename: newModelName)
                    
                    return
                }
            }
        }
    }
    
    private func pathExists(from start: String, to end: String) -> Bool {
        var visited = Set<String>()
        var queue = [(entity: start, fromPort: 0)] // Track which MC port we came from
        visited.insert(start)
        
        while !queue.isEmpty {
            let (current, fromPort) = queue.removeFirst()
            
            if current == end {
                return true
            }
            
            if cleanName(current).contains("switch") {
                let isClosed = switchStates[current] ?? false // Default to OPEN
                if !isClosed {
                    continue
                }
            }
            
            if cleanName(current).contains("PushB") {
                let isPressed = pushButtonStates[current] ?? false // Default to not pressed (OPEN)
                if !isPressed {
                    continue
                }
            }
            
            if cleanName(current).contains("Microcontroller") {
                if !isBatteryConnectedToMCPowerPort(mcName: current, batteryName: start) {
                    continue // Can't pass through this microcontroller
                }
                
                if let neighbors = connectionGraph[current] {
                    for neighbor in neighbors {
                        if !visited.contains(neighbor) {
                            let portNum = getPortNumberForConnection(mcName: current, connectedEntity: neighbor)
                            
                            if portNum == 0 {
                                continue
                            }
                            
                            let isHigh = getMicrocontrollerPortState(mcName: current, port: portNum)
                            
                            if isHigh {
                                visited.insert(neighbor)
                                queue.append((neighbor, portNum))
                            } else {
                            }
                        }
                    }
                }
                continue // Don't use the normal neighbor exploration below
            }
            
            if let neighbors = connectionGraph[current] {
                for neighbor in neighbors {
                    if !visited.contains(neighbor) {
                        visited.insert(neighbor)
                        queue.append((neighbor, fromPort))
                    }
                }
            }
        }
        
        return false
    }
    
    private func isBatteryConnectedToMCPowerPort(mcName: String, batteryName: String) -> Bool {
        
        for wrapper in allEntities {
            if let modelChild = wrapper.children.first(where: { $0.name != "SelectionHighlight" }) {
                if modelChild.name == mcName {
                    let powerPorts = findAllEntitiesRecursive(name: "mainPortP", in: modelChild)
                    
                    if powerPorts.isEmpty {
                        return false
                    }
                    
                    for powerPort in powerPorts {
                        let powerPortWorldPos = powerPort.position(relativeTo: nil)
                        
                        for batteryWrapper in allEntities {
                            if let batteryChild = batteryWrapper.children.first(where: { $0.name != "SelectionHighlight" }) {
                                if batteryChild.name == batteryName {
                                    let batteryPorts = findAllEntitiesRecursive(name: "mainPort", in: batteryChild)
                                    
                                    for batteryPort in batteryPorts {
                                        let batteryPortWorldPos = batteryPort.position(relativeTo: nil)
                                        let distance = simd_distance(powerPortWorldPos, batteryPortWorldPos)
                                        
                                        if distance < connectionThreshold {
                                            return true
                                        }
                                    }
                                    
                                    if let mcNeighbors = connectionGraph[mcName] {
                                        for neighbor in mcNeighbors {
                                            for neighborWrapper in allEntities {
                                                if let neighborChild = neighborWrapper.children.first(where: { $0.name != "SelectionHighlight" }) {
                                                    if neighborChild.name == neighbor {
                                                        let neighborPorts = findAllEntitiesRecursive(name: "mainPort", in: neighborChild)
                                                        
                                                        for neighborPort in neighborPorts {
                                                            let neighborPortWorldPos = neighborPort.position(relativeTo: nil)
                                                            let distanceToMainPortP = simd_distance(powerPortWorldPos, neighborPortWorldPos)
                                                            
                                                            if distanceToMainPortP < connectionThreshold {
                                                                if pathExistsExcludingMC(from: batteryName, to: neighbor, excludingMC: mcName) {
                                                                    return true
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    return false
                }
            }
        }
        
        return false
    }
    
    private func pathExistsExcludingMC(from start: String, to end: String, excludingMC: String) -> Bool {
        var visited = Set<String>()
        var queue = [start]
        visited.insert(start)
        
        while !queue.isEmpty {
            let current = queue.removeFirst()
            
            if current == end {
                return true
            }
            
            if current == excludingMC {
                continue
            }
            
            if cleanName(current).contains("switch") {
                let isClosed = switchStates[current] ?? false
                if !isClosed {
                    continue
                }
            }
            
            if cleanName(current).contains("PushB") {
                let isPressed = pushButtonStates[current] ?? false
                if !isPressed {
                    continue
                }
            }
            
            if let neighbors = connectionGraph[current] {
                for neighbor in neighbors {
                    if !visited.contains(neighbor) && neighbor != excludingMC {
                        visited.insert(neighbor)
                        queue.append(neighbor)
                    }
                }
            }
        }
        
        return false
    }
    
    func updateUltrasonicDistances(arView: ARView) {
        for wrapper in allEntities {
            guard let model = wrapper.children.first(where: { $0.name != "SelectionHighlight" }),
                  cleanName(model.name).contains("Ultrasonic") else { continue }
            
            let entityName = model.name
            
            guard isConnectedToMCPort(entityName: entityName),
                  connectedSensorIDs.contains(entityName) else {
                ultrasonicDistances[entityName] = nil
                continue
            }
            
            let referenceEntities = findAllEntitiesRecursive(name: "Reference", in: model)
            let origin: SIMD3<Float>
            if let ref = referenceEntities.first {
                origin = ref.position(relativeTo: nil)
            } else {
                origin = model.position(relativeTo: nil)
            }
            
            let forward = model.convert(direction: SIMD3<Float>(0, 0, 1), to: nil)
            let rayDirection = normalize(forward)
            
            let query = ARRaycastQuery(origin: origin,
                                       direction: rayDirection,
                                       allowing: .estimatedPlane,
                                       alignment: .vertical)
            let results = arView.session.raycast(query)
            
            if results.isEmpty {
                ultrasonicDistances[entityName] = nil
            } else {
                let closest = results.min(by: {
                    simd_distance($0.worldTransform.columns.3.xyz, origin) <
                        simd_distance($1.worldTransform.columns.3.xyz, origin)
                })!
                let hitPos = closest.worldTransform.columns.3.xyz
                ultrasonicDistances[entityName] = simd_distance(hitPos, origin)
            }
        }
    }
    
    
    func updateLightSensorReadings(arView: ARView) {
        guard let lightEstimate = arView.session.currentFrame?.lightEstimate else {
            for wrapper in allEntities {
                guard let model = wrapper.children.first(where: { $0.name != "SelectionHighlight" }),
                      cleanName(model.name).contains("LightSensor") else { continue }
                lightSensorReadings[model.name] = nil
            }
            return
        }
        
        let ambientIntensity = lightEstimate.ambientIntensity
        
        for wrapper in allEntities {
            guard let model = wrapper.children.first(where: { $0.name != "SelectionHighlight" }),
                  cleanName(model.name).contains("LightSensor") else { continue }
            
            let entityName = model.name
            
            guard isConnectedToMCPort(entityName: entityName),
                  connectedSensorIDs.contains(entityName) else {
                lightSensorReadings[entityName] = nil
                continue
            }
            
            lightSensorReadings[entityName] = Float(ambientIntensity)
        }
    }
    
    func getUltrasonicReading() -> Float? {
        for wrapper in allEntities {
            guard let model = wrapper.children.first(where: { $0.name != "SelectionHighlight" }),
                  cleanName(model.name).contains("Ultrasonic") else { continue }
            if let distanceOpt = ultrasonicDistances[model.name], let distance = distanceOpt {
                return distance * 100 // Convert to cm
            }
        }
        return nil
    }
    
    func getLightSensorReading() -> Float? {
        for wrapper in allEntities {
            guard let model = wrapper.children.first(where: { $0.name != "SelectionHighlight" }),
                  cleanName(model.name).contains("LightSensor") else { continue }
            if let luxOpt = lightSensorReadings[model.name], let lux = luxOpt {
                return lux
            }
        }
        return nil
    }
    
    private func isConnectedToMCPort(entityName: String) -> Bool {
        var visited = Set<String>()
        var queue = [entityName]
        visited.insert(entityName)
        
        while !queue.isEmpty {
            let current = queue.removeFirst()
            
            if cleanName(current).contains("Microcontroller") {
                if portNumberConnecting(entityName: entityName, mcName: current) > 0 {
                    return true
                }
                if let mcWrapper = allEntities.first(where: {
                    ($0.children.first(where: { $0.name != "SelectionHighlight" }))?.name == current
                }), let mcModel = mcWrapper.children.first(where: { $0.name != "SelectionHighlight" }) {
                    for portNum in [1, 2, 3] {
                        let mcPorts = findAllEntitiesRecursive(name: "mainPort\(portNum)", in: mcModel)
                        if let neighbors = connectionGraph[current] {
                            for neighbor in neighbors where neighbor != entityName {
                                guard let nWrapper = allEntities.first(where: {
                                    ($0.children.first(where: { $0.name != "SelectionHighlight" }))?.name == neighbor
                                }), let nModel = nWrapper.children.first(where: { $0.name != "SelectionHighlight" }) else { continue }
                                let nPorts = findAllEntitiesRecursive(name: "mainPort", in: nModel)
                                for mcPort in mcPorts {
                                    let mcPos = mcPort.position(relativeTo: nil)
                                    for nPort in nPorts {
                                        if simd_distance(mcPos, nPort.position(relativeTo: nil)) < connectionThreshold {
                                            if pathExistsExcludingMC(from: entityName, to: neighbor, excludingMC: current) {
                                                return true
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                continue
            }
            
            if let neighbors = connectionGraph[current] {
                for neighbor in neighbors where !visited.contains(neighbor) {
                    visited.insert(neighbor)
                    queue.append(neighbor)
                }
            }
        }
        return false
    }
    
    private func portNumberConnecting(entityName: String, mcName: String) -> Int {
        guard let eWrapper = allEntities.first(where: {
            ($0.children.first(where: { $0.name != "SelectionHighlight" }))?.name == entityName
        }), let eModel = eWrapper.children.first(where: { $0.name != "SelectionHighlight" }),
              let mWrapper = allEntities.first(where: {
                  ($0.children.first(where: { $0.name != "SelectionHighlight" }))?.name == mcName
              }), let mModel = mWrapper.children.first(where: { $0.name != "SelectionHighlight" })
        else { return 0 }
        
        let ePorts = findAllEntitiesRecursive(name: "mainPort", in: eModel)
        for portNum in [1, 2, 3] {
            let mcPorts = findAllEntitiesRecursive(name: "mainPort\(portNum)", in: mModel)
            for mcPort in mcPorts {
                let mcPos = mcPort.position(relativeTo: nil)
                for ePort in ePorts {
                    if simd_distance(mcPos, ePort.position(relativeTo: nil)) < connectionThreshold {
                        return portNum
                    }
                }
            }
        }
        return 0
    }
    
    func cleanName(_ name: String) -> String {
        return name.components(separatedBy: "_").first ?? name
    }
    
    func getMicrocontrollerPortsInfo(mcName: String) -> [Int: [String]] {
        var portsInfo: [Int: [String]] = [1: [], 2: [], 3: []]
        
        
        if microcontrollerPortStates[mcName] == nil {
            microcontrollerPortStates[mcName] = [1: true, 2: true, 3: true]
        }
        
        var allBulbs: [String] = []
        for entityName in connectionGraph.keys {
            if cleanName(entityName).contains("Bulb") {
                allBulbs.append(entityName)
            }
        }
        
        
        for wrapper in allEntities {
            if let modelChild = wrapper.children.first(where: { $0.name != "SelectionHighlight" }) {
                if modelChild.name == mcName {
                    let port1Entities = findAllEntitiesRecursive(name: "mainPort1", in: modelChild)
                    let port2Entities = findAllEntitiesRecursive(name: "mainPort2", in: modelChild)
                    let port3Entities = findAllEntitiesRecursive(name: "mainPort3", in: modelChild)
                    
                    
                    portsInfo[1] = findBulbsReachableFromPort(ports: port1Entities, allBulbs: allBulbs, mcName: mcName)
                    portsInfo[2] = findBulbsReachableFromPort(ports: port2Entities, allBulbs: allBulbs, mcName: mcName)
                    portsInfo[3] = findBulbsReachableFromPort(ports: port3Entities, allBulbs: allBulbs, mcName: mcName)
                    
                    
                    break
                }
            }
        }
        
        return portsInfo
    }
    
    private func findBulbsReachableFromPort(ports: [Entity], allBulbs: [String], mcName: String) -> [String] {
        var reachableBulbs: [String] = []
        
        for port in ports {
            let portWorldPos = port.position(relativeTo: nil)
            
            for wrapper in allEntities {
                if let modelChild = wrapper.children.first(where: { $0.name != "SelectionHighlight" }) {
                    let entityName = modelChild.name
                    
                    if entityName == mcName { continue }
                    
                    let entityPorts = findAllEntitiesRecursive(name: "mainPort", in: modelChild)
                    
                    for entityPort in entityPorts {
                        let entityPortWorldPos = entityPort.position(relativeTo: nil)
                        let distance = simd_distance(portWorldPos, entityPortWorldPos)
                        
                        if distance < connectionThreshold {
                            
                            for bulbName in allBulbs {
                                if pathExistsExcludingMC(from: entityName, to: bulbName, excludingMC: mcName) {
                                    let cleanBulbName = cleanName(bulbName)
                                    if !reachableBulbs.contains(cleanBulbName) {
                                        reachableBulbs.append(cleanBulbName)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return reachableBulbs
    }
    
    func getMicrocontrollerPortState(mcName: String, port: Int) -> Bool {
        return microcontrollerPortStates[mcName]?[port] ?? true
    }
    
    func setMicrocontrollerPortState(mcName: String, port: Int, isHigh: Bool) {
        if microcontrollerPortStates[mcName] == nil {
            microcontrollerPortStates[mcName] = [:]
        }
        microcontrollerPortStates[mcName]?[port] = isHigh
        
        
        checkConnections(entities: allEntities)
    }
    
    private func getPortNumberForConnection(mcName: String, connectedEntity: String) -> Int {
        for wrapper in allEntities {
            if let modelChild = wrapper.children.first(where: { $0.name != "SelectionHighlight" }) {
                if modelChild.name == mcName {
                    let port1Entities = findAllEntitiesRecursive(name: "mainPort1", in: modelChild)
                    let port2Entities = findAllEntitiesRecursive(name: "mainPort2", in: modelChild)
                    let port3Entities = findAllEntitiesRecursive(name: "mainPort3", in: modelChild)
                    
                    for entityWrapper in allEntities {
                        if let entityChild = entityWrapper.children.first(where: { $0.name != "SelectionHighlight" }) {
                            if entityChild.name == connectedEntity {
                                let entityPorts = findAllEntitiesRecursive(name: "mainPort", in: entityChild)
                                
                                for port1 in port1Entities {
                                    let port1WorldPos = port1.position(relativeTo: nil)
                                    for entityPort in entityPorts {
                                        let entityPortWorldPos = entityPort.position(relativeTo: nil)
                                        if simd_distance(port1WorldPos, entityPortWorldPos) < connectionThreshold {
                                            return 1
                                        }
                                    }
                                }
                                
                                for port2 in port2Entities {
                                    let port2WorldPos = port2.position(relativeTo: nil)
                                    for entityPort in entityPorts {
                                        let entityPortWorldPos = entityPort.position(relativeTo: nil)
                                        if simd_distance(port2WorldPos, entityPortWorldPos) < connectionThreshold {
                                            return 2
                                        }
                                    }
                                }
                                
                                for port3 in port3Entities {
                                    let port3WorldPos = port3.position(relativeTo: nil)
                                    for entityPort in entityPorts {
                                        let entityPortWorldPos = entityPort.position(relativeTo: nil)
                                        if simd_distance(port3WorldPos, entityPortWorldPos) < connectionThreshold {
                                            return 3
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return 0
    }
    
    private func findAllEntitiesRecursive(name: String, in entity: Entity) -> [Entity] {
        var results: [Entity] = []
        if entity.name == name { results.append(entity) }
        for child in entity.children {
            results.append(contentsOf: findAllEntitiesRecursive(name: name, in: child))
        }
        return results
    }
}

// ARView Container

class PushButtonARView: ARView {
    weak var coordinator: ARViewContainer.Coordinator?
    private var holdTimer: Timer?
    private var pendingPushBName: String?
    private var isHoldActive = false
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        if let entity = self.entity(at: location),
           let pushBName = findPushBName(from: entity) {
            pendingPushBName = pushBName
            isHoldActive = false
            
            holdTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
                guard let self = self, let name = self.pendingPushBName else { return }
                self.isHoldActive = true
                self.coordinator?.connectionManager.setPushButtonState(entityName: name, isPressed: true)
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        cancelHold()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        cancelHold()
    }
    
    private func cancelHold() {
        holdTimer?.invalidate()
        holdTimer = nil
        pendingPushBName = nil
        if isHoldActive {
            isHoldActive = false
            coordinator?.connectionManager.releaseAllPushButtons()
        }
    }
    
    private func findPushBName(from entity: Entity) -> String? {
        var current: Entity? = entity
        while let c = current {
            if c.name.contains("PushB") { return c.name }
            if c.name == "DraggableWrapper" {
                for child in c.children {
                    if child.name.contains("PushB") { return child.name }
                }
            }
            current = c.parent
        }
        return nil
    }
}

struct ARViewContainer: UIViewRepresentable {
    static var sharedARView: ARView?
    var selectionManager: SelectionManager
    var connectionManager: ConnectionManager
    
    func makeUIView(context: Context) -> ARView {
        let arView = PushButtonARView(frame: .zero)
        arView.coordinator = context.coordinator
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        arView.session.run(config)
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        let doubleTapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        arView.addGestureRecognizer(doubleTapGesture)
        
        tapGesture.require(toFail: doubleTapGesture)
        
        let rotationGesture = UIRotationGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleRotation(_:)))
        arView.addGestureRecognizer(rotationGesture)
        
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        arView.addGestureRecognizer(panGesture)
        
        ARViewContainer.sharedARView = arView
        context.coordinator.arView = arView
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            connectionManager.updateUltrasonicDistances(arView: arView)
            connectionManager.updateLightSensorReadings(arView: arView)
        }
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(selectionManager: selectionManager, connectionManager: connectionManager)
    }
    
    class Coordinator: NSObject {
        var selectionManager: SelectionManager
        var connectionManager: ConnectionManager
        weak var arView: ARView?
        
        init(selectionManager: SelectionManager, connectionManager: ConnectionManager) {
            self.selectionManager = selectionManager
            self.connectionManager = connectionManager
        }
        
        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            let tapLocation = recognizer.location(in: arView)
            var shouldDeselect = true
            
            if let entity = arView.entity(at: tapLocation) {
                var currentEntity: Entity? = entity
                var depth = 0
                while let current = currentEntity {
                    if current.components.has(InputTargetComponent.self) &&
                        current.name == "DraggableWrapper" {
                        selectionManager.selectEntity(current)
                        shouldDeselect = false
                        break
                    }
                    currentEntity = current.parent
                    depth += 1
                }
                if shouldDeselect { selectionManager.deselectEntity() }
            } else {
            }
            
            if shouldDeselect { selectionManager.deselectEntity() }
        }
        
        @objc func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            let tapLocation = recognizer.location(in: arView)
            
            if let entity = arView.entity(at: tapLocation) {
                var currentEntity: Entity? = entity
                while let current = currentEntity {
                    if current.components.has(InputTargetComponent.self) &&
                        current.name == "DraggableWrapper" {
                        
                        if let entityName = findModelName(in: current) {
                            let cleanEntityName = connectionManager.cleanName(entityName)
                            if cleanEntityName.contains("switch") {
                                connectionManager.toggleSwitch(entityName: entityName)
                                return
                            } else if cleanEntityName.contains("MicrocontrollerM") {
                                onMicrocontrollerLongPress?(entityName)
                                return
                            } else {
                            }
                        }
                    }
                    currentEntity = current.parent
                }
            }
        }
        
        func findModelName(in wrapper: Entity) -> String? {
            for child in wrapper.children {
                if child.name == "SelectionHighlight" { continue }
                if !child.name.isEmpty { return child.name }
            }
            return nil
        }
        
        @objc func handleRotation(_ recognizer: UIRotationGestureRecognizer) {
            guard let selected = selectionManager.selectedEntity else { return }
            if recognizer.state == .changed {
                let rotation = Float(recognizer.rotation)
                selected.orientation *= simd_quatf(angle: -rotation, axis: [0, 1, 0])
                recognizer.rotation = 0
            }
        }
        
        @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
            guard let arView = arView else { return }
            
            if selectionManager.selectedEntity == nil && recognizer.state == .began {
                onDragWithoutSelectionCallback?()
                return
            }
            
            guard let selected = selectionManager.selectedEntity else { return }
            let location = recognizer.location(in: arView)
            
            switch recognizer.state {
            case .changed:
                guard let tableEntity = tableEntity else { return }
                guard let rayResult = arView.ray(through: location) else { return }
                let tablePosition = tableEntity.position(relativeTo: nil)
                let tableHeight: Float = 0.1
                let planeY = tablePosition.y + tableHeight / 2
                let rayOrigin = rayResult.origin
                let rayDirection = rayResult.direction
                if rayDirection.y != 0 {
                    let t = (planeY - rayOrigin.y) / rayDirection.y
                    if t > 0 {
                        let intersectionPoint = rayOrigin + t * rayDirection
                        let localPoint = tableEntity.convert(position: intersectionPoint, from: nil)
                        let currentY = selected.position.y
                        selected.position = [localPoint.x, currentY, localPoint.z]
                    }
                }
                
            case .ended:
                checkConnections()
                onDragEndCallback?()
                
            default:
                break
            }
        }
        
        func checkConnections() {
            guard let tableEntity = tableEntity else { return }
            let entities = tableEntity.children.filter { $0.name == "DraggableWrapper" }
            connectionManager.checkConnections(entities: entities, selectionManager: selectionManager)
        }
    }
}

// Global References

var tableEntity: ModelEntity?
var tableAnchor: AnchorEntity?
var globalSelectionManager: SelectionManager?
var onDragEndCallback: (() -> Void)?
var onSwitchToggleCallback: (() -> Void)?
var onMicrocontrollerLongPress: ((String) -> Void)?
var onDragWithoutSelectionCallback: (() -> Void)?

func playSnapSound() {
    AudioServicesPlaySystemSound(1156)
}

// Spawn Table

func spawnTable(showMessage: Binding<String?>) {
    spawnTableWithCallback(showMessage: showMessage, onSuccess: nil)
}

func spawnTableWithCallback(showMessage: Binding<String?>, onSuccess: (() -> Void)?) {
    guard let arView = ARViewContainer.sharedARView else { return }
    let center = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
    let results = arView.raycast(from: center, allowing: .estimatedPlane, alignment: .horizontal)
    
    guard let hit = results.first else {
        showMessage.wrappedValue = "Move device: flat surface needed!"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showMessage.wrappedValue = nil }
        return
    }
    
    showMessage.wrappedValue = nil
    tableAnchor?.removeFromParent()
    
    let anchor = AnchorEntity(world: hit.worldTransform)
    tableAnchor = anchor
    
    let tableWidth: Float = 1
    let tableHeight: Float = 0.01
    let tableDepth: Float = 0.5
    
    let table = ModelEntity(
        mesh: .generateBox(width: tableWidth, height: tableHeight, depth: tableDepth),
        materials: [SimpleMaterial(color: .gray, isMetallic: false)]
    )
    table.position.y = tableHeight / 2
    table.generateCollisionShapes(recursive: false)
    table.components.set(InputTargetComponent())
    tableEntity = table
    
    let markerSize: Float = 0.02  // 2cm square markers
    let markerMaterial = SimpleMaterial(color: .yellow, isMetallic: false)
    
    let corners: [(x: Float, z: Float)] = [
        (x: tableWidth / 2, z: tableDepth / 2),      // Front-right
        (x: -tableWidth / 2, z: tableDepth / 2),     // Front-left
        (x: tableWidth / 2, z: -tableDepth / 2),     // Back-right
        (x: -tableWidth / 2, z: -tableDepth / 2)     // Back-left
    ]
    
    for corner in corners {
        let marker = ModelEntity(
            mesh: .generateBox(width: markerSize, height: tableHeight, depth: markerSize),
            materials: [markerMaterial]
        )
        marker.position = [corner.x, 0, corner.z]
        table.addChild(marker)
    }
    
    anchor.addChild(table)
    arView.scene.addAnchor(anchor)
    onSuccess?()
}

// Clear All Entities

func clearAllEntities() {
    guard let table = tableEntity else { return }
    let allWrappers = table.children.filter { $0.name == "DraggableWrapper" }
    for wrapper in allWrappers { wrapper.removeFromParent() }
    if let arView = ARViewContainer.sharedARView,
       let coordinator = arView.gestureRecognizers?.first?.delegate as? ARViewContainer.Coordinator {
        coordinator.connectionManager.connections.removeAll()
        coordinator.selectionManager.selectedEntity = nil
    }
}

// Spawn Entity

func spawnEntity(fileName: String) {
    spawnEntityWithCallback(fileName: fileName, onSuccess: nil)
}

func spawnEntityWithCallback(fileName: String, onSuccess: (() -> Void)?) {
    guard let table = tableEntity else { return }
    
    do {
        let micro = try ModelEntity.load(named: fileName)
        
        func findAllEntitiesRecursive(name: String, in entity: Entity) -> [Entity] {
            var results: [Entity] = []
            if entity.name == name { results.append(entity) }
            for child in entity.children { results.append(contentsOf: findAllEntitiesRecursive(name: name, in: child)) }
            return results
        }
        
        let allMainPorts = findAllEntitiesRecursive(name: "mainPort", in: micro)
        if !allMainPorts.isEmpty {
            for portMain in allMainPorts {
                if let simpBld = portMain.children.first as? ModelEntity {
                    var mainMaterial = SimpleMaterial()
                    mainMaterial.color = .init(tint: .green, texture: nil)
                    simpBld.model?.materials = [mainMaterial]
                }
            }
        } else {
        }
        
        micro.scale = [1.5, 1.5, 1.5]
        micro.generateCollisionShapes(recursive: true)
        let uniqueID = UUID().uuidString.prefix(8)
        micro.name = "\(fileName)_\(uniqueID)"
        
        let bounds = micro.visualBounds(relativeTo: micro)
        let scaleMultiplier: Float = 1.5
        let wrapperSize = bounds.extents * scaleMultiplier
        let wrapperMesh = MeshResource.generateBox(size: wrapperSize)
        var material = SimpleMaterial()
        material.color = .init(tint: .clear, texture: nil)
        let wrapper = ModelEntity(mesh: wrapperMesh, materials: [material])
        wrapper.name = "DraggableWrapper"
        
        let wrapperShape = ShapeResource.generateBox(size: wrapperSize)
        wrapper.components.set(CollisionComponent(shapes: [wrapperShape]))
        wrapper.components.set(InputTargetComponent())
        
        let tableHeight: Float = 0.1
        let tableWidth: Float = 1.0
        let tableDepth: Float = 0.5
        let wrapperBottomY: Float = tableHeight / 2 + wrapperSize.y / 2  // Remove the 0.02 gap
        
        wrapper.position = [tableWidth/2 - 0.1, wrapperBottomY, -tableDepth/2 + 0.1]
        wrapper.orientation = simd_quatf(angle: -.pi/2, axis: [0, 1, 0])
        wrapper.addChild(micro)
        micro.position = [
            -bounds.center.x,
             -bounds.center.y - wrapperSize.y / 2 + bounds.extents.y / 2,
             -bounds.center.z
        ]
        
        table.addChild(wrapper)
        if let selectionManager = globalSelectionManager { selectionManager.selectEntity(wrapper) }
        onSuccess?()
        
    } catch {
    }
}

// Delete Entity

func deleteEntity(named entityName: String, from tableEntity: Entity?, connectionManager: ConnectionManager, selectionManager: SelectionManager) {
    guard let table = tableEntity else { return }
    
    let wrapperToDelete = table.children.first { wrapper in
        wrapper.children.first(where: { $0.name != "SelectionHighlight" })?.name == entityName
    }
    
    if let wrapper = wrapperToDelete {
        connectionManager.connections.removeAll { $0.contains(entityName) }
        
        wrapper.removeFromParent()
        
        selectionManager.selectedEntity = nil
        
        let remainingEntities = table.children.filter { $0.name == "DraggableWrapper" }
        connectionManager.checkConnections(entities: remainingEntities, selectionManager: selectionManager)
    }
}

// Microcontroller Info Popup

struct MicrocontrollerInfoPopup: View {
    let portsInfo: [Int: [String]]
    let portStates: [Int: Bool]
    let onPortStateChanged: (Int, Bool) -> Void
    let onProgramButtonTapped: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }
            
            VStack {
                Spacer().frame(height: 150)
                
                VStack(spacing: 20) {
                    Text("Microcontroller Ports")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Bulbs reachable from each output port")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                    
                    VStack(spacing: 15) {
                        ForEach([1, 2, 3], id: \.self) { portNum in
                            let connectedEntities = portsInfo[portNum] ?? []
                            let isHigh = portStates[portNum] ?? true
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Circle()
                                        .fill(portColor(portNum))
                                        .frame(width: 12, height: 12)
                                    Text("Port \(portNum)")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Button(action: { onPortStateChanged(portNum, !isHigh) }) {
                                        HStack(spacing: 8) {
                                            Text(isHigh ? "HIGH" : "LOW")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.white)
                                            Rectangle()
                                                .fill(isHigh ? Color.green : Color.red)
                                                .frame(width: 50, height: 25)
                                                .cornerRadius(12.5)
                                                .overlay(
                                                    Circle()
                                                        .fill(Color.white)
                                                        .frame(width: 21, height: 21)
                                                        .offset(x: isHigh ? 12 : -12)
                                                )
                                        }
                                    }
                                }
                                
                                if connectedEntities.isEmpty {
                                    Text("No bulbs connected")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.5))
                                        .italic()
                                        .padding(.leading, 20)
                                } else {
                                    VStack(alignment: .leading, spacing: 4) {
                                        ForEach(connectedEntities, id: \.self) { entityName in
                                            HStack {
                                                Text("•").foregroundColor(.green)
                                                Text(cleanEntityName(entityName))
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.white.opacity(0.9))
                                            }
                                            .padding(.leading, 20)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.1)))
                        }
                    }
                    .frame(maxWidth: 350)
                    
                    HStack(spacing: 15) {
                        Button(action: onProgramButtonTapped) {
                            HStack {
                                Image(systemName: "chevron.left.forwardslash.chevron.right")
                                Text("Program")
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                            .cornerRadius(10)
                            .shadow(color: Color.blue.opacity(0.5), radius: 8, x: 0, y: 4)
                        }
                        Button("Close") { onDismiss() }
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(Color.gray.opacity(0.6))
                            .cornerRadius(10)
                    }
                }
                .padding(30)
                .frame(maxHeight: 500)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(LinearGradient(gradient: Gradient(colors: [Color(red: 0.2, green: 0.3, blue: 0.5).opacity(0.95), Color(red: 0.15, green: 0.25, blue: 0.45).opacity(0.95)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                )
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.3), lineWidth: 2))
                .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
                
                Spacer().frame(height: 20)
            }
        }
    }
    
    private func cleanEntityName(_ name: String) -> String {
        return name.components(separatedBy: "_").first ?? name
    }
    
    private func portColor(_ port: Int) -> Color {
        switch port {
        case 1: return .red
        case 2: return .yellow
        case 3: return .green
        default: return .gray
        }
    }
}

// Entity Delete Popup

struct EntityDeletePopup: View {
    let entityName: String
    let onDelete: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }
            
            VStack(spacing: 20) {
                Image(systemName: "trash.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.red)
                Text("Delete Entity")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                Text("Are you sure you want to delete this \(cleanEntityName(entityName))?")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                HStack(spacing: 15) {
                    Button(action: onDelete) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Delete")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(LinearGradient(gradient: Gradient(colors: [Color.red, Color.red.opacity(0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .cornerRadius(10)
                        .shadow(color: Color.red.opacity(0.5), radius: 8, x: 0, y: 4)
                    }
                    Button("Cancel") { onDismiss() }
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.6))
                        .cornerRadius(10)
                }
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(gradient: Gradient(colors: [Color(red: 0.15, green: 0.15, blue: 0.2), Color(red: 0.1, green: 0.1, blue: 0.15)]), startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.2), lineWidth: 1))
            .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
        }
    }
    
    private func cleanEntityName(_ name: String) -> String {
        return name.components(separatedBy: "_").first ?? name
    }
}

// Floating Delete Button

struct FloatingDeleteButton: View {
    let selectedEntity: Entity
    let topPadding: CGFloat
    let onDelete: () -> Void
    
    var body: some View {
        if topPadding > 0 {
            VStack {
                Spacer().frame(height: topPadding)
                HStack {
                    Spacer()
                    deleteButton
                        .padding(.trailing, 20)
                }
                Spacer()
            }
            .zIndex(1500)
        } else {
            deleteButton
        }
    }
    
    private var deleteButton: some View {
        Button(action: onDelete) {
            HStack(spacing: 8) {
                Image(systemName: "trash.fill").font(.system(size: 18))
                Text("Delete").font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(LinearGradient(gradient: Gradient(colors: [Color.red.opacity(0.9), Color.red.opacity(0.7)]), startPoint: .topLeading, endPoint: .bottomTrailing))
            .cornerRadius(25)
            .shadow(color: .red.opacity(0.4), radius: 8, x: 0, y: 4)
        }
    }
}

// Rotation Control Widget

struct RotationControl: View {
    let selectedEntity: Entity
    let bottomPadding: CGFloat
    @State private var rotation: Angle = .zero
    @State private var isDragging = false
    
    private let snapAngles: [Double] = [0, 90, 180, 270]
    private let snapThreshold: Double = 15
    
    var body: some View {
        if bottomPadding > 0 {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    rotationWheel
                        .padding(.trailing, 20)
                        .padding(.bottom, bottomPadding)
                }
                Spacer()
            }
            .zIndex(1501)
        } else {
            rotationWheel
        }
    }
    
    private var rotationWheel: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.3), lineWidth: 2).frame(width: 120, height: 120)
            Circle().stroke(Color.white.opacity(0.5), lineWidth: 2).frame(width: 80, height: 80)
            
            ForEach(snapAngles, id: \.self) { angle in
                Circle()
                    .fill(Color.yellow.opacity(0.6))
                    .frame(width: 6, height: 6)
                    .offset(x: cos(angle * .pi / 180) * 60, y: sin(angle * .pi / 180) * 60)
            }
            
            Circle().fill(Color.white.opacity(0.6)).frame(width: 8, height: 8)
            
            Circle()
                .fill(LinearGradient(gradient: Gradient(colors: [isSnapped() ? Color.yellow.opacity(0.9) : Color.blue.opacity(0.9), isSnapped() ? Color.yellow.opacity(0.7) : Color.blue.opacity(0.7)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 30, height: 30)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .shadow(color: isSnapped() ? .yellow.opacity(0.7) : .blue.opacity(0.5), radius: isDragging ? 10 : 6, x: 0, y: 0)
                .offset(x: cos(rotation.radians) * 45, y: sin(rotation.radians) * 45)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            isDragging = true
                            let center = CGPoint(x: 60, y: 60)
                            let vector = CGPoint(x: value.location.x - center.x, y: value.location.y - center.y)
                            let angle = atan2(vector.y, vector.x)
                            var newRotationDegrees = angle * 180 / .pi
                            if newRotationDegrees < 0 { newRotationDegrees += 360 }
                            let snappedAngle = snapToAngle(newRotationDegrees)
                            let newRotation = Angle(degrees: snappedAngle)
                            let delta = newRotation.radians - rotation.radians
                            selectedEntity.orientation *= simd_quatf(angle: Float(delta), axis: [0, 1, 0])
                            rotation = newRotation
                        }
                        .onEnded { _ in isDragging = false }
                )
            
            Text("\(Int(rotation.degrees.truncatingRemainder(dividingBy: 360)))°")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isSnapped() ? .yellow : .white)
                .offset(y: -70)
        }
        .frame(width: 120, height: 120)
    }
    
    private func isSnapped() -> Bool {
        let currentDegrees = rotation.degrees.truncatingRemainder(dividingBy: 360)
        let normalized = currentDegrees < 0 ? currentDegrees + 360 : currentDegrees
        for snapAngle in snapAngles { if abs(normalized - snapAngle) < 2 { return true } }
        return false
    }
    
    private func snapToAngle(_ degrees: Double) -> Double {
        for snapAngle in snapAngles { if abs(degrees - snapAngle) < snapThreshold { return snapAngle } }
        if abs(degrees - 360) < snapThreshold { return 0 }
        return degrees
    }
}

// Sensor Display View Helper

struct SensorDisplayView: View {
    let title: String
    let reading: Float?
    let formatter: (Float) -> String
    let activeColor: Color
    let index: Int
    
    var body: some View {
        let displayText: String
        let textColor: Color
        
        if let value = reading {
            displayText = formatter(value)
            textColor = activeColor
        } else {
            displayText = "--"
            textColor = Color.white.opacity(0.4)
        }
        
        return VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(activeColor.opacity(0.8))
            Text(displayText)
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundColor(textColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.7))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(activeColor.opacity(0.5), lineWidth: 1)
        )
    }
}
