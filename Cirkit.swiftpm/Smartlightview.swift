import SwiftUI
import RealityKit
import ARKit

struct SmartLightView: View {
    @State private var surfaceMessage: String? = nil
    @StateObject private var selectionManager = SelectionManager()
    @StateObject private var connectionManager = ConnectionManager()
    @State private var currentStepIndex = 0
    @State private var tableSuccessfullyPlaced = false
    @State private var showMicrocontrollerPopup = false
    @State private var selectedMicrocontrollerEntity: String? = nil
    @State private var showMicrocontrollerProgramming = false
    @State private var savedPrograms: [String: [ProgramBlock]] = [:]
    @State private var showFullscreenCircuitImage = false
    @State private var displayedMessage: String = ""
    @State private var isTyping: Bool = false
    @State private var typewriterWorkItems: [DispatchWorkItem] = []
    @State private var showDragReminderPopup = false
    @State private var dragAttemptCount = 0
    @State private var lastDragAttemptTime: Date? = nil
    
    let steps = [
        "Point your device at a real table or the floor and press \"Add Table\" button on the left.",
        "Drag the microcontroller to connect it to the circuit like shown in the target circuit. Then double tap it to open the popup and click </> Program, then press \"Run\". Hold the yellow push button to see the lights switch on and release to switch off."
    ]
    
    var currentStep: String {
        steps[min(currentStepIndex, steps.count - 1)]
    }
    
    var body: some View {
        ZStack {
            ARViewContainer(
                selectionManager: selectionManager,
                connectionManager: connectionManager
            )
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                globalSelectionManager = selectionManager
                
                onDragWithoutSelectionCallback = {
                    let now = Date()
                    if let lastAttempt = self.lastDragAttemptTime,
                       now.timeIntervalSince(lastAttempt) < 10 {
                        self.dragAttemptCount += 1
                    } else {
                        self.dragAttemptCount = 1
                    }
                    self.lastDragAttemptTime = now
                    
                    if self.dragAttemptCount >= 2 {
                        withAnimation {
                            self.showDragReminderPopup = true
                        }
                        self.dragAttemptCount = 0  // Reset after showing
                    }
                }
                
                onMicrocontrollerLongPress = { entityName in
                    self.selectedMicrocontrollerEntity = entityName
                    self.showMicrocontrollerPopup = true
                }
            }
            .onChange(of: tableSuccessfullyPlaced) { oldValue, newValue in
                if newValue && currentStepIndex == 0 {
                    currentStepIndex = 1
                }
            }
            
            VStack {
                TutorialBanner(
                    message: displayedMessage,
                    navigationType: currentStepIndex == 0 ? .none : (currentStepIndex == steps.count - 1 ? .none : .continueOnly),
                    onPreviousTap: {},
                    onContinueTap: {
                        if currentStepIndex < steps.count - 1 {
                            currentStepIndex += 1
                        }
                    },
                    showInstructionImage: false
                )
                .padding(.horizontal, 20)
                .zIndex(3000)
                
                Spacer()
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .onChange(of: currentStepIndex) { oldValue, newValue in
                startTypewriterEffect(for: steps[newValue])
            }
            .onAppear {
                startTypewriterEffect(for: steps[0])
            }
            
            VStack {
                Spacer().frame(height: 140)
                
                HStack {
                    Spacer()
                    
                    CircuitProgressView(
                        imageName: "Image6",
                        onInfoTap: {
                            showFullscreenCircuitImage = true
                        }
                    )
                    .padding(.trailing, 20)
                }
                
                Spacer()
            }
            .zIndex(999)
            
            VStack {
                Spacer().frame(height: 180)  // Space for banner + circuit progress
                
                VStack(spacing: 8) {
                    Button("Clear") { clearAllEntities() }
                        .buttonStyle(ClearButtonStyle())
                    
                    Button("Add Table") {
                        spawnTableWithCallback(showMessage: $surfaceMessage) {
                            tableSuccessfullyPlaced = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                spawnPrebuiltCircuit()
                            }
                        }
                    }
                    
                    Button("Microcontroller") {
                        spawnEntity(fileName: "MicrocontrollerM")
                    }
                    
                    Button("Battery") {
                        spawnEntity(fileName: "Battery5")
                    }
                    
                    Button("Bulb") {
                        spawnEntity(fileName: "Bulb")
                    }
                    
                    Button("Wire") {
                        spawnEntity(fileName: "Wire4")
                    }
                    
                    Button("Switch") {
                        spawnEntity(fileName: "switch")
                    }
                    
                    Button("Push Button") {
                        spawnEntity(fileName: "PushB")
                    }
                }
                .buttonStyle(TutorialButtonStyle())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 20)
                
                Spacer()
            }
            .zIndex(998)
            
            VStack(spacing: 0) {
                Spacer().frame(height: 320) // Top spacing below banner + circuit progress
                
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
                    }
                    .padding(.trailing, 20)
                }
                
                Spacer()
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .zIndex(500)
            
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
            
            if showFullscreenCircuitImage {
                FullscreenCircuitImagePopup(
                    imageName: "Image6",
                    onDismiss: {
                        showFullscreenCircuitImage = false
                    }
                )
                .zIndex(2002)
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
                .zIndex(2001)
            }
            
            if showDragReminderPopup {
                VStack {
                    Spacer()
                    
                    HStack {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.yellow)
                        
                        Text("Select entity first by tapping on the entity")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.85))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.yellow, lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                    .padding(.bottom, 100)
                }
                .zIndex(2500)
                .transition(.opacity)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                        withAnimation {
                            showDragReminderPopup = false
                        }
                    }
                }
            }
            
            if let message = surfaceMessage {
                VStack {
                    Text(message)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.top, 200)
                    Spacer()
                }
                .zIndex(2000)
            }
        }
    }
    
    func clearAllEntities() {
        guard let table = tableEntity else { return }
        let allWrappers = table.children.filter { $0.name == "DraggableWrapper" }
        for wrapper in allWrappers {
            wrapper.removeFromParent()
        }
        connectionManager.connections.removeAll()
        selectionManager.selectedEntity = nil
    }
    
    
    // Typewriter Effect
    
    func startTypewriterEffect(for message: String) {
        for workItem in typewriterWorkItems {
            workItem.cancel()
        }
        typewriterWorkItems.removeAll()
        
        displayedMessage = ""
        isTyping = true
        
        let characters = Array(message)
        for (index, character) in characters.enumerated() {
            let workItem = DispatchWorkItem {
                self.displayedMessage.append(character)
                if index == characters.count - 1 {
                    self.isTyping = false
                }
            }
            typewriterWorkItems.append(workItem)
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.03, execute: workItem)
        }
    }
    
    // Spawn Prebuilt Circuit
    
    func spawnPrebuiltCircuit() {
        guard let table = tableEntity else { return }
        
        let tableHeight: Float = 0.1
        
        func loadAndPlace(fileName: String, xPos: Float, zPos: Float, rotationY: Float = -.pi/2) {
            guard let model = try? ModelEntity.load(named: fileName) else { return }
            
            func findPorts(name: String, in e: Entity) -> [Entity] {
                var r: [Entity] = []
                if e.name == name { r.append(e) }
                for c in e.children { r.append(contentsOf: findPorts(name: name, in: c)) }
                return r
            }
            
            for port in findPorts(name: "mainPort", in: model) {
                if let mesh = port.children.first as? ModelEntity {
                    var mat = SimpleMaterial()
                    mat.color = .init(tint: .green, texture: nil)
                    mesh.model?.materials = [mat]
                }
            }
            
            model.scale = [1.5, 1.5, 1.5]
            model.generateCollisionShapes(recursive: true)
            model.name = "\(fileName)_\(UUID().uuidString.prefix(8))"
            
            let bounds = model.visualBounds(relativeTo: model)
            let scaleMultiplier: Float = 1.5
            let wrapperSize = bounds.extents * scaleMultiplier
            var mat = SimpleMaterial()
            mat.color = .init(tint: .clear, texture: nil)
            let wrapper = ModelEntity(mesh: MeshResource.generateBox(size: wrapperSize), materials: [mat])
            wrapper.name = "DraggableWrapper"
            wrapper.components.set(CollisionComponent(shapes: [ShapeResource.generateBox(size: wrapperSize)]))
            wrapper.components.set(InputTargetComponent())
            
            let wrapperBottomY = tableHeight / 2 + wrapperSize.y / 2
            wrapper.position = [xPos, wrapperBottomY, zPos]
            wrapper.orientation = simd_quatf(angle: rotationY, axis: [0, 1, 0])
            wrapper.addChild(model)
            model.position = [
                -bounds.center.x,
                 -bounds.center.y - wrapperSize.y / 2 + bounds.extents.y / 2,
                 -bounds.center.z
            ]
            table.addChild(wrapper)
        }
        
        loadAndPlace(fileName: "MicrocontrollerM", xPos: -0.009, zPos: -0.18, rotationY: .pi * 2)
        
        loadAndPlace(fileName: "Battery5",          xPos:  0.349, zPos:  0.026)
        loadAndPlace(fileName: "Wire4",             xPos:  0.177, zPos:  0.025)
        loadAndPlace(fileName: "Wire4",             xPos: -0.112, zPos:  0.000)
        loadAndPlace(fileName: "Wire4",             xPos: -0.197, zPos:  0.050)
        loadAndPlace(fileName: "Wire4",             xPos:  0.095, zPos:  0.095)
        loadAndPlace(fileName: "Bulb",              xPos: -0.243, zPos:  0.000, rotationY: .pi/2)
        loadAndPlace(fileName: "Bulb",              xPos: -0.328, zPos:  0.050, rotationY: .pi/2)
        loadAndPlace(fileName: "PushB",             xPos:  0.199, zPos:  0.139)
        
        let allWrappers = table.children.filter { $0.name == "DraggableWrapper" }
        connectionManager.checkConnections(entities: allWrappers, selectionManager: selectionManager)
        
        if let _mcWrapper = allWrappers.first(where: { wrapper in
            wrapper.children.first(where: { $0.name != "SelectionHighlight" })?.name.contains("MicrocontrollerM") == true
        }), let mcModel = _mcWrapper.children.first(where: { $0.name != "SelectionHighlight" }) {
            let mcEntityName = mcModel.name
            
            let ifId = UUID()
            
            var forever = ProgramBlock(type: .foreverLoop)
            forever.indentLevel = 0
            
            var ifBlock = ProgramBlock(type: .ifCondition(mode: .portBased(port1: true, port2: nil, port3: nil), ifId: ifId))
            ifBlock.indentLevel = 1
            
            var ifPort = ProgramBlock(type: .portControl(port1: nil, port2: true, port3: true))
            ifPort.indentLevel = 2
            
            var elseBlock = ProgramBlock(type: .elseBlock(ifId: ifId))
            elseBlock.indentLevel = 1
            
            var elsePort = ProgramBlock(type: .portControl(port1: nil, port2: false, port3: false))
            elsePort.indentLevel = 2
            
            savedPrograms[mcEntityName] = [forever, ifBlock, ifPort, elseBlock, elsePort]
            
            connectionManager.setMicrocontrollerPortState(mcName: mcEntityName, port: 1, isHigh: false)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let mcWrapper = allWrappers.first(where: { wrapper in
                wrapper.children.first(where: { $0.name != "SelectionHighlight" })?.name.contains("MicrocontrollerM") == true
            }) {
                selectionManager.selectEntity(mcWrapper)
            }
        }
    }
}
