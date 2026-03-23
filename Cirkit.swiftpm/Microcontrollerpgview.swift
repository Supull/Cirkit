import SwiftUI

// Block Types

enum SensorType: String, CaseIterable {
    case ultrasonic = "Distance"
    case light = "Light"
}

enum ComparisonOperator: String, CaseIterable {
    case greaterThan = ">"
    case lessThan = "<"
    case equalTo = "="
}

enum IfConditionMode: Equatable {
    case portBased(port1: Bool?, port2: Bool?, port3: Bool?)
    case sensorBased(sensor: SensorType, op: ComparisonOperator, value: Float)
    
    var isPortBased: Bool {
        if case .portBased = self { return true }
        return false
    }
}

enum BlockType: Equatable {
    case portControl(port1: Bool?, port2: Bool?, port3: Bool?)  // nil = ANY (don't change)
    case wait(seconds: Double)
    case repeatLoop(times: Int, blocks: [ProgramBlock])
    case ifCondition(mode: IfConditionMode, ifId: UUID)
    case elseBlock(ifId: UUID)  // paired with ifCondition by ifId
    case foreverLoop
    case startProgram
}

struct ProgramBlock: Identifiable, Equatable {
    let id = UUID()
    var type: BlockType
    var position: CGPoint = .zero
    var indentLevel: Int = 0  // 0 = top level, 1 = inside first container, etc.
    
    var displayText: String {
        switch type {
        case .portControl(let p1, let p2, let p3):
            func portStr(_ v: Bool?) -> String { v == nil ? "ANY" : (v! ? "HIGH" : "LOW") }
            return "P1:\(portStr(p1))  P2:\(portStr(p2))  P3:\(portStr(p3))"
        case .wait(let seconds):
            return "Wait \(String(format: "%.1f", seconds))s"
        case .repeatLoop(let times, _):
            return "Repeat \(times) times"
        case .foreverLoop:
            return "Forever"
        case .ifCondition(let mode, _):
            switch mode {
            case .portBased(let p1, let p2, let p3):
                var conditions: [String] = []
                if let p1 = p1 { conditions.append("P1:\(p1 ? "HIGH" : "LOW")") }
                if let p2 = p2 { conditions.append("P2:\(p2 ? "HIGH" : "LOW")") }
                if let p3 = p3 { conditions.append("P3:\(p3 ? "HIGH" : "LOW")") }
                return "IF " + (conditions.isEmpty ? "always" : conditions.joined(separator: " & "))
            case .sensorBased(let sensor, let op, let value):
                return "IF \(sensor.rawValue) \(op.rawValue) \(String(format: "%.0f", value))"
            }
        case .elseBlock:
            return "ELSE"
        case .startProgram:
            return "START PROGRAM"
        }
    }
    
    var color: Color {
        switch type {
        case .portControl:
            return Color.blue
        case .wait:
            return Color.orange
        case .repeatLoop:
            return Color.purple
        case .foreverLoop:
            return Color(red: 0.8, green: 0.2, blue: 0.6)
        case .ifCondition:
            return Color.green
        case .elseBlock:
            return Color(red: 0.1, green: 0.6, blue: 0.4)
        case .startProgram:
            return Color.green
        }
    }
    
    var isContainer: Bool {
        switch type {
        case .repeatLoop, .ifCondition, .foreverLoop, .elseBlock:
            return true
        default:
            return false
        }
    }
    
    var nestedBlocks: [ProgramBlock] {
        if case .repeatLoop(_, let blocks) = type {
            return blocks
        }
        return []
    }
    
    mutating func updateNestedBlocks(_ blocks: [ProgramBlock]) {
        if case .repeatLoop(let times, _) = type {
            type = .repeatLoop(times: times, blocks: blocks)
        }
    }
}

// Main Programming View

struct MicrocontrollerProgrammingView: View {
    let mcEntityName: String
    @ObservedObject var connectionManager: ConnectionManager
    let onMinimize: ([ProgramBlock]) -> Void
    let onClose: () -> Void
    
    @State private var availableBlocks: [ProgramBlock] = []
    @State private var programBlocks: [ProgramBlock] = []
    @State private var draggingBlock: ProgramBlock?
    @State private var currentExecutingIndex: Int? = nil
    @State private var showProjectsMenu = false
    
    var isRunning: Bool {
        connectionManager.mcRunningStates[mcEntityName] ?? false
    }
    
    init(mcEntityName: String, connectionManager: ConnectionManager, initialBlocks: [ProgramBlock], onMinimize: @escaping ([ProgramBlock]) -> Void, onClose: @escaping () -> Void) {
        self.mcEntityName = mcEntityName
        self._connectionManager = ObservedObject(wrappedValue: connectionManager)
        self.onMinimize = onMinimize
        self.onClose = onClose
        
        _availableBlocks = State(initialValue: [
            ProgramBlock(type: .portControl(port1: false, port2: false, port3: false)),
            
            ProgramBlock(type: .wait(seconds: 1.0)),
            
            ProgramBlock(type: .repeatLoop(times: 5, blocks: [])),
            
            ProgramBlock(type: .ifCondition(mode: .portBased(port1: nil, port2: nil, port3: nil), ifId: UUID())),
            
            ProgramBlock(type: .foreverLoop)
        ])
        
        _programBlocks = State(initialValue: initialBlocks)
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                    .frame(height: 150)  // Space for tutorial banner
                
                HStack(spacing: 0) {
                    blockPalette
                        .frame(width: 200)
                    
                    programmingArea
                        .frame(maxWidth: .infinity)
                }
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.1, green: 0.15, blue: 0.25),
                            Color(red: 0.15, green: 0.2, blue: 0.3)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(20)
                .frame(maxWidth: 950, maxHeight: 450)  // Widened for extra buttons
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
                
                Spacer()
                    .frame(height: 20)  // Bottom padding
            }
            
            if showProjectsMenu {
                ProjectsMenuView(
                    onSelectTrafficLight: {
                        loadTrafficLightSimulator()
                        showProjectsMenu = false
                    },
                    onSelectBlinker: {
                        loadBlinker()
                        showProjectsMenu = false
                    },
                    onSelectSmartLight: {
                        loadSmartLightControl()
                        showProjectsMenu = false
                    },
                    onSelectAutoLight: {
                        loadAutoLightSensor()
                        showProjectsMenu = false
                    },
                    onDismiss: {
                        showProjectsMenu = false
                    }
                )
                .zIndex(3000)
            }
        }
    }
    
    // Block Palette
    
    var blockPalette: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Blocks")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.bottom, 10)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Hold and drag to use a block")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.yellow.opacity(0.8))
                        .padding(.bottom, 5)
                    
                    sectionHeader("PORT CONTROLS")
                    paletteBlockView(block: availableBlocks[0])
                    
                    sectionHeader("TIMING")
                    paletteBlockView(block: availableBlocks[1])
                    
                    sectionHeader("CONTROL")
                    paletteBlockView(block: availableBlocks[2])  // Repeat
                    paletteBlockView(block: availableBlocks[3])  // IF
                    paletteBlockView(block: availableBlocks[4])  // Forever
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
    }
    
    func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white.opacity(0.6))
            .padding(.top, 10)
    }
    
    func paletteBlockView(block: ProgramBlock) -> some View {
        BlockView(block: block, isExecuting: false)
            .onDrag {
                self.draggingBlock = block
                return NSItemProvider(object: block.id.uuidString as NSString)
            }
    }
    
    // Programming Area
    
    var programmingArea: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text("Program")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    showProjectsMenu = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "folder.fill")
                        Text("Projects")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.purple.opacity(0.8))
                    .cornerRadius(8)
                }
                
                Button(action: {
                    if !isRunning {
                        runProgram()
                        onMinimize(programBlocks)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill")
                        Text("Run")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isRunning ? Color.green.opacity(0.4) : Color.green)
                    .cornerRadius(8)
                }
                .disabled(isRunning)
                
                Button(action: {
                    stopProgram()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "stop.fill")
                        Text("Stop")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isRunning ? Color.red : Color.red.opacity(0.4))
                    .cornerRadius(8)
                }
                .disabled(!isRunning)
                
                Button(action: {
                    programBlocks.removeAll()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                        Text("Clear")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.6))
                    .cornerRadius(8)
                }
                
                Button(action: {
                    onMinimize(programBlocks)
                }) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.orange)
                        if isRunning {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 10, height: 10)
                                .offset(x: 3, y: -3)
                        }
                    }
                }
                
                Button(action: {
                    onClose()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding()
            
            Divider()
                .background(Color.white.opacity(0.3))
            
            ScrollView {
                VStack(spacing: 15) {
                    BlockView(
                        block: ProgramBlock(type: .startProgram),
                        isExecuting: currentExecutingIndex == -1
                    )
                    
                    if !programBlocks.isEmpty {
                        Image(systemName: "arrow.down")
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    ForEach(Array(programBlocks.enumerated()), id: \.element.id) { index, block in
                        VStack(spacing: 10) {
                            let nestingLevel = block.indentLevel
                            let isContainerBlock = block.isContainer
                            
                            HStack(spacing: 0) {
                                ForEach(0..<nestingLevel, id: \.self) { level in
                                    let borderColor: Color = level % 2 == 0 ? .purple : .green
                                    Rectangle()
                                        .fill(borderColor.opacity(0.5))
                                        .frame(width: 4)
                                    Spacer().frame(width: 8)
                                }
                                
                                if isContainerBlock {
                                    VStack(alignment: .leading, spacing: 0) {
                                        BlockView(
                                            block: $programBlocks[index],
                                            isExecuting: currentExecutingIndex == index,
                                            isEditable: true,
                                            onDelete: {
                                                deleteBlock(at: index)
                                            },
                                            onAddElse: {
                                                if case .ifCondition(_, let ifId) = block.type {
                                                    addElse(forIfAt: index, ifId: ifId)
                                                }
                                            },
                                            hasElse: {
                                                if case .ifCondition(_, let ifId) = block.type {
                                                    return programBlocks.contains(where: {
                                                        if case .elseBlock(let eId) = $0.type { return eId == ifId }
                                                        return false
                                                    })
                                                }
                                                return false
                                            }()
                                        )
                                        
                                        let containerColor: Color = {
                                            switch block.type {
                                            case .repeatLoop: return .purple
                                            case .ifCondition: return .green
                                            case .foreverLoop: return Color(red: 0.8, green: 0.2, blue: 0.6)
                                            case .elseBlock: return Color(red: 0.1, green: 0.6, blue: 0.4)
                                            default: return .purple
                                            }
                                        }()
                                        let containerMessage: String = {
                                            switch block.type {
                                            case .repeatLoop: return "  ↓ Blocks below will repeat"
                                            case .ifCondition: return "  ↓ Blocks below run if condition true"
                                            case .foreverLoop: return "  ↓ Blocks below run forever ∞"
                                            case .elseBlock: return "  ↓ Blocks below run if IF was false"
                                            default: return "  ↓ Blocks below"
                                            }
                                        }()
                                        HStack(spacing: 0) {
                                            Rectangle()
                                                .fill(containerColor.opacity(0.4))
                                                .frame(width: 4)
                                            VStack(alignment: .leading, spacing: 0) {
                                                Rectangle()
                                                    .fill(containerColor.opacity(0.4))
                                                    .frame(height: 4)
                                                Text(containerMessage)
                                                    .font(.system(size: 10))
                                                    .foregroundColor(containerColor.opacity(0.7))
                                                    .padding(.leading, 8)
                                            }
                                        }
                                        .frame(height: 30)
                                    }
                                } else {
                                    BlockView(
                                        block: $programBlocks[index],
                                        isExecuting: currentExecutingIndex == index,
                                        isEditable: true,
                                        onDelete: {
                                            deleteBlock(at: index)
                                        },
                                        onAddElse: {
                                            if case .ifCondition(_, let ifId) = block.type {
                                                addElse(forIfAt: index, ifId: ifId)
                                            }
                                        },
                                        hasElse: {
                                            if case .ifCondition(_, let ifId) = block.type {
                                                return programBlocks.contains(where: {
                                                    if case .elseBlock(let eId) = $0.type { return eId == ifId }
                                                    return false
                                                })
                                            }
                                            return false
                                        }()
                                    )
                                }
                                
                                VStack(spacing: 4) {
                                    let isElse = { if case .elseBlock = block.type { return true }; return false }()
                                    Button(action: {
                                        if programBlocks[index].indentLevel > 0 {
                                            programBlocks[index].indentLevel -= 1
                                        }
                                    }) {
                                        Image(systemName: "arrow.left.to.line")
                                            .font(.system(size: 12))
                                            .foregroundColor((!isElse && programBlocks[index].indentLevel > 0) ? .white.opacity(0.8) : .white.opacity(0.2))
                                            .frame(width: 28, height: 28)
                                            .background(Color.white.opacity(0.1))
                                            .cornerRadius(6)
                                    }
                                    .disabled(isElse || programBlocks[index].indentLevel == 0)
                                    
                                    Button(action: {
                                        let maxIndent = openScopeCount(for: index)
                                        if programBlocks[index].indentLevel < maxIndent {
                                            programBlocks[index].indentLevel += 1
                                        }
                                    }) {
                                        Image(systemName: "arrow.right.to.line")
                                            .font(.system(size: 12))
                                            .foregroundColor({
                                                if isElse { return Color.white.opacity(0.2) }
                                                let maxIndent = openScopeCount(for: index)
                                                return programBlocks[index].indentLevel < maxIndent ? .white.opacity(0.8) : .white.opacity(0.2)
                                            }())
                                            .frame(width: 28, height: 28)
                                            .background(Color.white.opacity(0.1))
                                            .cornerRadius(6)
                                    }
                                    .disabled(isElse)
                                }
                                .padding(.leading, 8)
                            }
                            
                            if index < programBlocks.count - 1 {
                                HStack(spacing: 0) {
                                    ForEach(0..<nestingLevel, id: \.self) { _ in
                                        Spacer().frame(width: 12)
                                    }
                                    Image(systemName: "arrow.down")
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                        }
                    }
                    
                    if draggingBlock != nil {
                        Text("Drop block here")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(height: 60)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                    .foregroundColor(.white.opacity(0.3))
                            )
                            .padding(.horizontal)
                    }
                }
                .padding()
            }
            .onDrop(of: [.text], isTargeted: nil) { providers in
                if let block = draggingBlock {
                    let newBlock = ProgramBlock(type: block.type)
                    programBlocks.append(newBlock)
                    draggingBlock = nil
                    return true
                }
                return false
            }
        }
        .background(Color.black.opacity(0.2))
    }
    
    // Else / Delete Helpers
    
    func addElse(forIfAt ifIndex: Int, ifId: UUID) {
        let ifLevel = programBlocks[ifIndex].indentLevel
        var insertAt = ifIndex + 1
        while insertAt < programBlocks.count && programBlocks[insertAt].indentLevel > ifLevel {
            insertAt += 1
        }
        var elseBlock = ProgramBlock(type: .elseBlock(ifId: ifId))
        elseBlock.indentLevel = ifLevel
        programBlocks.insert(elseBlock, at: insertAt)
    }
    
    func deleteBlock(at index: Int) {
        let block = programBlocks[index]
        switch block.type {
        case .ifCondition(_, let ifId):
            if let elseIndex = programBlocks.firstIndex(where: {
                if case .elseBlock(let eId) = $0.type { return eId == ifId }
                return false
            }) {
                let elseLevel = programBlocks[elseIndex].indentLevel
                var removeEnd = elseIndex + 1
                while removeEnd < programBlocks.count && programBlocks[removeEnd].indentLevel > elseLevel {
                    removeEnd += 1
                }
                programBlocks.removeSubrange(elseIndex..<removeEnd)
            }
            if index < programBlocks.count {
                programBlocks.remove(at: index)
            }
        case .elseBlock:
            let elseLevel = programBlocks[index].indentLevel
            var removeEnd = index + 1
            while removeEnd < programBlocks.count && programBlocks[removeEnd].indentLevel > elseLevel {
                removeEnd += 1
            }
            programBlocks.removeSubrange(index..<removeEnd)
        default:
            programBlocks.remove(at: index)
        }
    }
    
    // Scope Calculation
    
    func openScopeCount(for index: Int) -> Int {
        guard index > 0 else { return 0 }
        
        var openScopes: [Int] = [] // stack of indent levels of open containers
        
        for i in 0..<index {
            let b = programBlocks[i]
            
            if b.isContainer {
                openScopes.removeAll { $0 >= b.indentLevel }
                openScopes.append(b.indentLevel)
            } else {
                openScopes.removeAll { $0 >= b.indentLevel }
            }
        }
        
        return openScopes.count
    }
    
    // Load Traffic Light Simulator
    
    func loadTrafficLightSimulator() {
        programBlocks = [
            ProgramBlock(type: .portControl(port1: false, port2: false, port3: false)),
            ProgramBlock(type: .wait(seconds: 1.0)),
            
            ProgramBlock(type: .portControl(port1: true, port2: false, port3: false)),
            ProgramBlock(type: .wait(seconds: 1.0)),
            
            ProgramBlock(type: .portControl(port1: false, port2: true, port3: false)),
            ProgramBlock(type: .wait(seconds: 1.0)),
            
            ProgramBlock(type: .portControl(port1: false, port2: false, port3: true)),
            ProgramBlock(type: .wait(seconds: 1.0)),
            
            ProgramBlock(type: .portControl(port1: false, port2: false, port3: false))
        ]
    }
    
    // Load Blinker
    
    func loadBlinker() {
        var allLow = ProgramBlock(type: .portControl(port1: false, port2: false, port3: false))
        allLow.indentLevel = 1
        var allHigh = ProgramBlock(type: .portControl(port1: true, port2: true, port3: true))
        allHigh.indentLevel = 1
        programBlocks = [
            ProgramBlock(type: .repeatLoop(times: 10, blocks: [])),
            allLow,
            allHigh
        ]
    }
    
    // Load Smart Light Control System
    
    func loadSmartLightControl() {
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
        
        programBlocks = [forever, ifBlock, ifPort, elseBlock, elsePort]
    }
    
    // Load Automatic Light Sensor
    
    func loadAutoLightSensor() {
        let ifId = UUID()
        
        var forever = ProgramBlock(type: .foreverLoop)
        forever.indentLevel = 0
        
        var ifBlock = ProgramBlock(type: .ifCondition(mode: .sensorBased(sensor: .light, op: .lessThan, value: 350), ifId: ifId))
        ifBlock.indentLevel = 1
        
        var ifPort = ProgramBlock(type: .portControl(port1: nil, port2: true, port3: true))
        ifPort.indentLevel = 2
        
        var elseBlock = ProgramBlock(type: .elseBlock(ifId: ifId))
        elseBlock.indentLevel = 1
        
        var elsePort = ProgramBlock(type: .portControl(port1: nil, port2: false, port3: false))
        elsePort.indentLevel = 2
        
        programBlocks = [forever, ifBlock, ifPort, elseBlock, elsePort]
    }
    
    // Program Execution
    
    func runProgram() {
        guard !programBlocks.isEmpty else { return }
        
        connectionManager.mcRunningStates[mcEntityName] = true
        currentExecutingIndex = -1
        
        let task = Task {
            await executeProgram()
        }
        connectionManager.mcRunningTasks[mcEntityName] = task
    }
    
    func stopProgram() {
        connectionManager.mcRunningStates[mcEntityName] = false
        connectionManager.mcRunningTasks[mcEntityName]?.cancel()
        connectionManager.mcRunningTasks[mcEntityName] = nil
        currentExecutingIndex = nil
    }
    
    func executeProgram() async {
        currentExecutingIndex = -1
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        await executeBlocksInRange(0..<programBlocks.count, repeatCount: 1)
        
        await MainActor.run {
            currentExecutingIndex = nil
            connectionManager.mcRunningStates[mcEntityName] = false
            connectionManager.mcRunningTasks[mcEntityName] = nil
        }
    }
    
    func executeBlocksInRange(_ range: Range<Int>, repeatCount: Int) async {
        for _ in 0..<repeatCount {
            guard isRunning else { return }
            
            var i = range.lowerBound
            while i < range.upperBound && isRunning {
                let block = programBlocks[i]
                currentExecutingIndex = i
                let blockLevel = block.indentLevel
                
                switch block.type {
                case .portControl(let p1, let p2, let p3):
                    await MainActor.run {
                        if let p1 = p1 { connectionManager.setMicrocontrollerPortState(mcName: mcEntityName, port: 1, isHigh: p1) }
                        if let p2 = p2 { connectionManager.setMicrocontrollerPortState(mcName: mcEntityName, port: 2, isHigh: p2) }
                        if let p3 = p3 { connectionManager.setMicrocontrollerPortState(mcName: mcEntityName, port: 3, isHigh: p3) }
                    }
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    i += 1
                    
                case .wait(let seconds):
                    try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                    i += 1
                    
                case .repeatLoop(let times, _):
                    var innerRange: [Int] = []
                    var j = i + 1
                    while j < range.upperBound {
                        let nextBlock = programBlocks[j]
                        if nextBlock.indentLevel <= blockLevel {
                            break
                        }
                        innerRange.append(j)
                        j += 1
                    }
                    
                    if !innerRange.isEmpty {
                        let innerStart = innerRange.first!
                        let innerEnd = innerRange.last! + 1
                        await executeBlocksInRange(innerStart..<innerEnd, repeatCount: times)
                    }
                    
                    i = j
                    
                case .foreverLoop:
                    var innerRange: [Int] = []
                    var j = i + 1
                    while j < range.upperBound {
                        if programBlocks[j].indentLevel <= blockLevel { break }
                        innerRange.append(j)
                        j += 1
                    }
                    
                    if !innerRange.isEmpty {
                        let innerStart = innerRange.first!
                        let innerEnd = innerRange.last! + 1
                        while isRunning {
                            await executeBlocksInRange(innerStart..<innerEnd, repeatCount: 1)
                        }
                    }
                    i = range.upperBound
                    
                case .ifCondition(let mode, let ifId):
                    var conditionMet = false
                    
                    switch mode {
                    case .portBased(let checkP1, let checkP2, let checkP3):
                        let currentP1 = await MainActor.run {
                            connectionManager.getMicrocontrollerPortState(mcName: mcEntityName, port: 1)
                        }
                        let currentP2 = await MainActor.run {
                            connectionManager.getMicrocontrollerPortState(mcName: mcEntityName, port: 2)
                        }
                        let currentP3 = await MainActor.run {
                            connectionManager.getMicrocontrollerPortState(mcName: mcEntityName, port: 3)
                        }
                        
                        conditionMet = true
                        if let c1 = checkP1, c1 != currentP1 { conditionMet = false }
                        if let c2 = checkP2, c2 != currentP2 { conditionMet = false }
                        if let c3 = checkP3, c3 != currentP3 { conditionMet = false }
                        
                    case .sensorBased(let sensor, let op, let targetValue):
                        let sensorValue: Float? = await MainActor.run {
                            switch sensor {
                            case .ultrasonic:
                                return connectionManager.getUltrasonicReading()
                            case .light:
                                return connectionManager.getLightSensorReading()
                            }
                        }
                        
                        if let value = sensorValue {
                            switch op {
                            case .greaterThan:
                                conditionMet = value > targetValue
                            case .lessThan:
                                conditionMet = value < targetValue
                            case .equalTo:
                                conditionMet = abs(value - targetValue) < 1.0 // Allow 1 unit tolerance
                            }
                        } else {
                            conditionMet = false
                        }
                    }
                    
                    var innerRange: [Int] = []
                    var j = i + 1
                    while j < range.upperBound {
                        let nextBlock = programBlocks[j]
                        if nextBlock.indentLevel <= blockLevel { break }
                        innerRange.append(j)
                        j += 1
                    }
                    
                    var elseInnerRange: [Int] = []
                    var k = j
                    if k < range.upperBound,
                       case .elseBlock(let eId) = programBlocks[k].type,
                       eId == ifId,
                       programBlocks[k].indentLevel == blockLevel {
                        k += 1
                        while k < range.upperBound {
                            if programBlocks[k].indentLevel <= blockLevel { break }
                            elseInnerRange.append(k)
                            k += 1
                        }
                    }
                    
                    if conditionMet {
                        if !innerRange.isEmpty {
                            await executeBlocksInRange(innerRange.first!..<(innerRange.last! + 1), repeatCount: 1)
                        }
                    } else {
                        if !elseInnerRange.isEmpty {
                            await executeBlocksInRange(elseInnerRange.first!..<(elseInnerRange.last! + 1), repeatCount: 1)
                        }
                    }
                    
                    i = elseInnerRange.isEmpty ? j : k
                    
                case .elseBlock:
                    var j = i + 1
                    while j < range.upperBound {
                        if programBlocks[j].indentLevel <= blockLevel { break }
                        j += 1
                    }
                    i = j
                    
                case .startProgram:
                    i += 1
                }
            }
        }
    }
}

// Block View Component

struct BlockView: View {
    @Binding var block: ProgramBlock
    let isExecuting: Bool
    let isEditable: Bool
    let onDelete: (() -> Void)?
    let onAddElse: (() -> Void)?
    let hasElse: Bool
    
    init(block: Binding<ProgramBlock>, isExecuting: Bool, isEditable: Bool = false, onDelete: (() -> Void)? = nil, onAddElse: (() -> Void)? = nil, hasElse: Bool = false) {
        self._block = block
        self.isExecuting = isExecuting
        self.isEditable = isEditable
        self.onDelete = onDelete
        self.onAddElse = onAddElse
        self.hasElse = hasElse
    }
    
    init(block: ProgramBlock, isExecuting: Bool) {
        self._block = .constant(block)
        self.isExecuting = isExecuting
        self.isEditable = false
        self.onDelete = nil
        self.onAddElse = nil
        self.hasElse = false
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch block.type {
            case .portControl(let p1, let p2, let p3):
                if isEditable {
                    VStack(spacing: 8) {
                        portConditionToggle(port: 1, checkState: p1) { newValue in
                            block.type = .portControl(port1: newValue, port2: p2, port3: p3)
                        }
                        portConditionToggle(port: 2, checkState: p2) { newValue in
                            block.type = .portControl(port1: p1, port2: newValue, port3: p3)
                        }
                        portConditionToggle(port: 3, checkState: p3) { newValue in
                            block.type = .portControl(port1: p1, port2: p2, port3: newValue)
                        }
                    }
                } else {
                    Text(block.displayText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                }
                
            case .wait(let seconds):
                if isEditable {
                    VStack(spacing: 5) {
                        HStack {
                            Text("Wait:")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                            Text("\(String(format: "%.1f", seconds))s")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.orange)
                        }
                        
                        HStack(spacing: 8) {
                            Text("0.1")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.6))
                            
                            Slider(value: Binding(
                                get: { seconds },
                                set: { newValue in
                                    block.type = .wait(seconds: newValue)
                                }
                            ), in: 0.1...10.0, step: 0.1)
                            .accentColor(.orange)
                            
                            Text("10")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                } else {
                    Text(block.displayText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                }
                
            case .repeatLoop(let times, _):
                if isEditable {
                    HStack {
                        Text("Repeat:")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            if times > 1 {
                                if case .repeatLoop(_, let blocks) = block.type {
                                    block.type = .repeatLoop(times: times - 1, blocks: blocks)
                                }
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                        }
                        
                        Text("\(times)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 40)
                        
                        Button(action: {
                            if times < 100 {
                                if case .repeatLoop(_, let blocks) = block.type {
                                    block.type = .repeatLoop(times: times + 1, blocks: blocks)
                                }
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                        }
                    }
                } else {
                    Text(block.displayText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                }
                
            case .ifCondition(let mode, let ifId):
                if isEditable {
                    VStack(spacing: 8) {
                        HStack {
                            Text("IF Mode:")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button(action: {
                                if case .sensorBased = mode {
                                    block.type = .ifCondition(mode: .portBased(port1: true, port2: nil, port3: nil), ifId: ifId)
                                }
                            }) {
                                Text("Port")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(mode.isPortBased ? Color.blue.opacity(0.6) : Color.clear)
                                    .cornerRadius(4)
                            }
                            
                            Button(action: {
                                if case .portBased = mode {
                                    block.type = .ifCondition(mode: .sensorBased(sensor: .ultrasonic, op: .greaterThan, value: 50), ifId: ifId)
                                }
                            }) {
                                Text("Sensor")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(!mode.isPortBased ? Color.cyan.opacity(0.6) : Color.clear)
                                    .cornerRadius(4)
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(6)
                        
                        switch mode {
                        case .portBased(let p1, let p2, let p3):
                            portConditionToggle(port: 1, checkState: p1) { newValue in
                                block.type = .ifCondition(mode: .portBased(port1: newValue, port2: p2, port3: p3), ifId: ifId)
                            }
                            portConditionToggle(port: 2, checkState: p2) { newValue in
                                block.type = .ifCondition(mode: .portBased(port1: p1, port2: newValue, port3: p3), ifId: ifId)
                            }
                            portConditionToggle(port: 3, checkState: p3) { newValue in
                                block.type = .ifCondition(mode: .portBased(port1: p1, port2: p2, port3: newValue), ifId: ifId)
                            }
                            
                        case .sensorBased(let sensor, let op, let value):
                            sensorControls(sensor: sensor, op: op, value: value, ifId: ifId)
                        }
                    }
                } else {
                    Text(block.displayText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                }
                
            case .startProgram:
                Text(block.displayText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                
            case .foreverLoop:
                HStack {
                    Text("∞  Forever")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Text("loops forever")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                }
                
            case .elseBlock:
                HStack {
                    Text("ELSE")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Text("runs if IF was false")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            if isEditable {
                HStack(spacing: 8) {
                    if case .ifCondition = block.type, !hasElse, let addElse = onAddElse {
                        Button(action: addElse) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.triangle.branch")
                                    .font(.system(size: 10))
                                Text("Add Else")
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(4)
                        }
                    }
                    
                    Spacer()
                    
                    if let delete = onDelete {
                        Button(action: delete) {
                            HStack(spacing: 4) {
                                Image(systemName: "trash")
                                    .font(.system(size: 10))
                                Text("Delete")
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.6))
                            .cornerRadius(4)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(block.color.opacity(isExecuting ? 1.0 : 0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isExecuting ? Color.yellow : Color.clear, lineWidth: 3)
        )
        .shadow(color: block.color.opacity(0.3), radius: isExecuting ? 8 : 4, x: 0, y: 2)
        .scaleEffect(isExecuting ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: isExecuting)
    }
    
    func portStateToggle(port: Int, state: Bool?, onChange: @escaping (Bool?) -> Void) -> some View {
        let label: String = state == nil ? "ANY" : (state! ? "HIGH" : "LOW")
        let bg: Color = state == nil ? .gray : (state! ? .green : .red)
        
        return HStack {
            Text("Port \(port):")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
            Button(action: {
                switch state {
                case nil:    onChange(false)
                case false:  onChange(true)
                default:     onChange(nil)
                }
            }) {
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 44)
                    .padding(.vertical, 5)
                    .background(bg.opacity(0.8))
                    .cornerRadius(6)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.1))
        .cornerRadius(6)
    }
    
    func portConditionToggle(port: Int, checkState: Bool?, onChange: @escaping (Bool?) -> Void) -> some View {
        HStack {
            Text("Port \(port):")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                onChange(nil)
            }) {
                Text("Any")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(checkState == nil ? .white : .white.opacity(0.5))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(checkState == nil ? Color.gray.opacity(0.6) : Color.clear)
                    .cornerRadius(4)
            }
            
            Button(action: {
                onChange(false)
            }) {
                Text("LOW")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(checkState == false ? .white : .white.opacity(0.5))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(checkState == false ? Color.red.opacity(0.6) : Color.clear)
                    .cornerRadius(4)
            }
            
            Button(action: {
                onChange(true)
            }) {
                Text("HIGH")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(checkState == true ? .white : .white.opacity(0.5))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(checkState == true ? Color.green.opacity(0.6) : Color.clear)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.1))
        .cornerRadius(6)
    }
    
    func sensorControls(sensor: SensorType, op: ComparisonOperator, value: Float, ifId: UUID) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text("Sensor:")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.8))
                
                ForEach(SensorType.allCases, id: \.self) { sensorOption in
                    Button(action: {
                        block.type = .ifCondition(mode: .sensorBased(sensor: sensorOption, op: op, value: value), ifId: ifId)
                    }) {
                        Text(sensorOption.rawValue)
                            .font(.system(size: 11, weight: sensorOption == sensor ? .bold : .regular))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(sensorOption == sensor ? Color.cyan : Color.white.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
            }
            
            HStack {
                Text("Operator:")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.8))
                
                ForEach(ComparisonOperator.allCases, id: \.self) { opOption in
                    Button(action: {
                        block.type = .ifCondition(mode: .sensorBased(sensor: sensor, op: opOption, value: value), ifId: ifId)
                    }) {
                        Text(opOption.rawValue)
                            .font(.system(size: 14, weight: opOption == op ? .bold : .regular))
                            .foregroundColor(.white)
                            .frame(width: 30, height: 30)
                            .background(opOption == op ? Color.green : Color.white.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Value: \(String(format: "%.0f", value))")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.yellow)
                
                Slider(value: Binding(
                    get: { value },
                    set: { newValue in
                        block.type = .ifCondition(mode: .sensorBased(sensor: sensor, op: op, value: newValue), ifId: ifId)
                    }
                ), in: 0...1000, step: 1)
                .accentColor(.yellow)
            }
        }
    }
}

// Projects Menu View

struct ProjectsMenuView: View {
    let onSelectTrafficLight: () -> Void
    let onSelectBlinker: () -> Void
    let onSelectSmartLight: () -> Void
    let onSelectAutoLight: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            VStack {
                Spacer()
                    .frame(height: 150)  // Space for tutorial banner
                
                VStack(spacing: 0) {
                    HStack {
                        Text("Select Project")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: onDismiss) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(20)
                    .background(Color.black.opacity(0.3))
                    
                    Divider()
                        .background(Color.white.opacity(0.3))
                    
                    ScrollView {
                        VStack(spacing: 15) {
                            Button(action: onSelectTrafficLight) {
                                HStack(spacing: 15) {
                                    Image(systemName: "light.beacon.max.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.white)
                                        .frame(width: 50, height: 50)
                                        .background(
                                            Circle()
                                                .fill(Color.red.opacity(0.3))
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text("Traffic Light Simulator")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.white)
                                        
                                        Text("Red → Yellow → Green pattern")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                .padding(15)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                            }
                            
                            Button(action: onSelectBlinker) {
                                HStack(spacing: 15) {
                                    Image(systemName: "light.beacon.max.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.yellow)
                                        .frame(width: 50)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Blinker")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.white)
                                        
                                        Text("All ports blink ON and OFF 10 times")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                .padding(15)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                            }
                            
                            Button(action: onSelectSmartLight) {
                                HStack(spacing: 15) {
                                    Image(systemName: "lightbulb.2.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.cyan)
                                        .frame(width: 50)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Smart Light Control")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.white)
                                        
                                        Text("IF sensor triggers port 1, turn on ports 2 & 3")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                .padding(15)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                            }
                            
                            Button(action: onSelectAutoLight) {
                                HStack(spacing: 15) {
                                    Image(systemName: "light.beacon.max.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.yellow)
                                        .frame(width: 50)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Automatic Light Sensor")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.white)
                                        
                                        Text("IF light < 350, turn lights ON, ELSE turn OFF")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                .padding(15)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                            }
                            
                            projectCardComingSoon(title: "Morse Code", icon: "antenna.radiowaves.left.and.right")
                            projectCardComingSoon(title: "Knight Rider", icon: "bolt.fill")
                            projectCardComingSoon(title: "Binary Counter", icon: "number")
                        }
                        .padding(20)
                    }  // ScrollView
                }
                .frame(maxWidth: 400, maxHeight: 450)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.2, green: 0.3, blue: 0.5).opacity(0.95),
                            Color(red: 0.15, green: 0.25, blue: 0.45).opacity(0.95)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
                
                Spacer()
                    .frame(height: 20)  // Bottom padding
            }
        }
    }
    
    func projectCardComingSoon(title: String, icon: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(.white.opacity(0.3))
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                )
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                
                Text("Coming Soon")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            Spacer()
        }
        .padding(15)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// Preview
#Preview {
    MicrocontrollerProgrammingView(
        mcEntityName: "Test_MC",
        connectionManager: ConnectionManager(),
        initialBlocks: [],
        onMinimize: { _ in },
        onClose: {}
    )
}
