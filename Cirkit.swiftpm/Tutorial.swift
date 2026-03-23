import SwiftUI
import RealityKit
import ARKit
import Combine

// Circuit Progress View (Image Only)

struct CircuitProgressView: View {
    let imageName: String  // Image to display
    let onInfoTap: () -> Void  // Callback when info button tapped
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "lightbulb.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.yellow)
                
                Text("Target Circuit")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("Fullscreen →")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.trailing, 4)
                
                Button(action: onInfoTap) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0.2)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.6),
                        Color.purple.opacity(0.6)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            
            ZStack {
                RoundedRectangle(cornerRadius: 0)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.4),
                                Color.black.opacity(0.3)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 75)
                    .cornerRadius(6)
                    .shadow(color: .blue.opacity(0.3), radius: 6, x: 0, y: 3)
                    .padding(6)
            }
            .frame(height: 90)
        }
        .frame(maxWidth: 250)
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.5),
                            Color.purple.opacity(0.5)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// Tutorial Banner Component

struct TutorialBanner: View {
    let message: String
    let navigationType: TutorialStep.NavigationType
    let onPreviousTap: () -> Void
    let onContinueTap: () -> Void
    let showInstructionImage: Bool // Show Image5 for instructions
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 15) {
                Image("Image2")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 45, height: 45)
                    .padding(10)
                    .background(
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ]),
                                    center: .center,
                                    startRadius: 5,
                                    endRadius: 30
                                )
                            )
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.4), lineWidth: 2)
                    )
                
                if showInstructionImage {
                    VStack(alignment: .leading, spacing: 12) {
                        InstructionCard(
                            number: "1",
                            text: "Please hold the iPad in landscape orientation",
                            color: .orange
                        )
                        
                        InstructionCard(
                            number: "2",
                            text: "Tap once on the entity to select an entity",
                            color: .blue
                        )
                        
                        InstructionCard(
                            number: "3",
                            text: "Make sure yellow upside down cone is on top of the selected entity which shows that the entity is selected",
                            color: .blue
                        )
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.yellow.opacity(0.5), lineWidth: 3)
                                )
                            
                            Image("Image5")
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(8)
                                .padding(8)
                        }
                        .frame(maxHeight: 180)
                        .shadow(color: .yellow.opacity(0.3), radius: 8, x: 0, y: 4)
                        
                        InstructionCard(
                            number: "4",
                            text: "Purple ports refer to the purple cuboid on each entity",
                            color: .purple
                        )
                        
                        InstructionCard(
                            number: "5",
                            text: "If you can't select an entity, bring the camera close to the entity and try again",
                            color: .orange
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                } else {
                    Text(message)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                }
                
                if navigationType == .continueOnly {
                    Button(action: onContinueTap) {
                        Text("Continue")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.green,
                                                Color.green.opacity(0.85)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: Color.green.opacity(0.5), radius: 6, x: 0, y: 3)
                            )
                    }
                    .padding(.leading, 8)
                } else if navigationType == .previousOnly {
                    Button(action: onPreviousTap) {
                        Text("Previous")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.gray.opacity(0.7),
                                                Color.gray.opacity(0.6)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 3)
                            )
                    }
                    .padding(.leading, 8)
                } else if navigationType == .prevAndContinue {
                    HStack(spacing: 8) {
                        Button(action: onPreviousTap) {
                            Text("Previous")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.gray.opacity(0.7),
                                                    Color.gray.opacity(0.6)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 3)
                                )
                        }
                        
                        Button(action: onContinueTap) {
                            Text("Continue")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.green,
                                                    Color.green.opacity(0.85)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: Color.green.opacity(0.5), radius: 6, x: 0, y: 3)
                                )
                        }
                    }
                    .padding(.leading, 8)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
        }
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.2, green: 0.3, blue: 0.5).opacity(0.95),
                            Color(red: 0.15, green: 0.25, blue: 0.45).opacity(0.95)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
        )
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }
}

// Tutorial Step

struct TutorialStep {
    let message: String
    let type: StepType
    let buttonText: String?
    let navigationType: NavigationType
    
    enum StepType {
        case message
        case action
    }
    
    enum NavigationType {
        case none              // No buttons
        case autoAdvance      // Auto-advance (like welcome screen)
        case continueOnly     // Only continue button
        case prevAndContinue  // Both previous and continue buttons
        case previousOnly     // Only previous button
    }
}

// Tutorial View

struct TutorialView: View {
    
    @State private var surfaceMessage: String? = nil
    @StateObject private var selectionManager = SelectionManager()
    @StateObject private var connectionManager = ConnectionManager()
    
    @State private var currentStepIndex = 0
    @State private var tableSuccessfullyPlaced = false
    @State private var batterySpawned = false
    @State private var wireSpawned = false
    @State private var switchSpawned = false
    @State private var bulbSpawned = false
    @State private var switchToggled = false
    @State private var entitiesCleared = false  // Track if Clear button was pressed
    
    @State private var tableCornersVisible = false
    @State private var borderColor: Color = .red
    @State private var greenBorderStartTime: Date? = nil
    
    @State private var displayedMessage: String = ""
    @State private var isTyping: Bool = false
    @State private var typewriterWorkItems: [DispatchWorkItem] = []
    
    @State private var showDragReminderPopup = false
    @State private var dragAttemptCount = 0
    @State private var lastDragAttemptTime: Date? = nil
    
    @State private var showMicrocontrollerPopup = false
    @State private var selectedMicrocontrollerEntity: String? = nil
    @State private var showMicrocontrollerProgramming = false
    @State private var savedPrograms: [String: [ProgramBlock]] = [:] // MC name -> saved blocks
    
    @State private var showFullscreenCircuitImage = false
    
    @State private var markerPosition: SIMD3<Float>?
    @State private var checkingMarkerPosition = false
    
    let tutorialSteps = [
        TutorialStep(message: "Welcome to Cirkit.", type: .message, buttonText: nil, navigationType: .autoAdvance),
        TutorialStep(message: "Instructions.", type: .message, buttonText: nil, navigationType: .continueOnly),
        TutorialStep(message: "Make sure to hold iPad in landscape orientation. Point your device at a real table or the floor and press \"Add Table\" button on the left.", type: .action, buttonText: nil, navigationType: .none),
        TutorialStep(message: "Add a battery by pressing \"Battery\" on the left.", type: .action, buttonText: nil, navigationType: .none),
        TutorialStep(message: "Drag the battery to the marked location.", type: .action, buttonText: nil, navigationType: .none),
        TutorialStep(message: "Add a wire by pressing \"Wire\" on the left.", type: .action, buttonText: nil, navigationType: .none),
        TutorialStep(message: "Bring one of the wire's purple ports close to the battery's purple port so that it snaps together.", type: .action, buttonText: nil, navigationType: .none),
        TutorialStep(message: "Add a switch by pressing \"Switch\" on the left.", type: .action, buttonText: nil, navigationType: .none),
        TutorialStep(message: "Bring the switch's purple port close to the wire's purple port so that it snaps together.", type: .action, buttonText: nil, navigationType: .none),
        TutorialStep(message: "Add a bulb by pressing \"Bulb\" on the left.", type: .action, buttonText: nil, navigationType: .none),
        TutorialStep(message: "Rotate the bulb 180 degrees like shown in the target circuit from the rotation joystick on the right of the screen. Bring the bulb's purple port close to the switch's purple port so that it snaps together.", type: .action, buttonText: nil, navigationType: .none),
        TutorialStep(message: "Now double tap on the switch you just fixed to the wire.", type: .action, buttonText: nil, navigationType: .none),
        TutorialStep(message: "Wow, you just built a circuit!", type: .message, buttonText: nil, navigationType: .continueOnly),
        TutorialStep(message: "Now clear all the entities on the table by pressing \"Clear\" on your left.", type: .action, buttonText: nil, navigationType: .none),
        TutorialStep(message: "Look how the microcontroller has four ports: three for a device such as a bulb, and the power port for the battery.", type: .action, buttonText: nil, navigationType: .prevAndContinue),
        TutorialStep(message: "Drag the microcontroller and fix it to the circuit like shown in the target circuit.", type: .action, buttonText: nil, navigationType: .prevAndContinue),
        TutorialStep(message: "Double tap the microcontroller to open the popup.", type: .action, buttonText: nil, navigationType: .prevAndContinue),
        TutorialStep(message: "Open the microcontroller popup, go to </> Programs → Projects, select Traffic Light Simulator. Now press \"Run\" and see the code run from the bulbs.", type: .action, buttonText: nil, navigationType: .prevAndContinue),
        TutorialStep(message: "Now check out the set projects in the Library in the home page by pressing \"Back\" on the top left for more preset projects.", type: .message, buttonText: nil, navigationType: .previousOnly)
    ]
    
    var currentStep: TutorialStep {
        tutorialSteps[min(currentStepIndex, tutorialSteps.count - 1)]
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
                
                onSwitchToggleCallback = {
                    if self.currentStepIndex == 11 {
                        self.switchToggled = true
                        if self.connectionManager.isPoweredOn {
                            self.currentStepIndex += 1
                            onSwitchToggleCallback = nil
                        }
                    }
                }
                
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
            
            VStack {
                TutorialBanner(
                    message: displayedMessage,
                    navigationType: currentStep.navigationType,
                    onPreviousTap: {
                        if currentStepIndex > 0 {
                            currentStepIndex -= 1
                        }
                    },
                    onContinueTap: { currentStepIndex += 1 },
                    showInstructionImage: currentStepIndex == 1 // Show Image5 on step 1
                )
                .onAppear {
                    if currentStepIndex == 0 {
                        startTypewriterEffect(for: currentStep.message)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            if currentStepIndex == 0 {
                                currentStepIndex += 1
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .onChange(of: currentStepIndex) { oldValue, newValue in
                startTypewriterEffect(for: tutorialSteps[newValue].message)
            }
            .zIndex(3000)
            
            if currentStep.type == .action && currentStepIndex >= 3 {
                VStack {
                    Spacer().frame(height: 140)  // Space for banner
                    
                    HStack {
                        Spacer()
                        
                        CircuitProgressView(
                            imageName: currentStepIndex >= 13 ? "Image4" : "Image3",
                            onInfoTap: {
                                showFullscreenCircuitImage = true
                            }
                        )
                        .padding(.trailing, 20)
                    }
                    
                    Spacer()
                }
                .zIndex(999)
            }
            
            if currentStep.type == .action {
                VStack {
                    Spacer().frame(height: 240)  // Space for banner + circuit progress
                    
                    VStack(spacing: 8) {
                        Button("Clear") {
                            clearAllEntities()
                            if currentStepIndex == 13 {
                                entitiesCleared = true
                                currentStepIndex += 1
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    spawnPrebuiltCircuit()
                                }
                            }
                        }
                        .buttonStyle(ClearButtonStyle())
                        
                        Button("Add Table") {
                            spawnTableWithCallback(showMessage: $surfaceMessage) {
                                tableSuccessfullyPlaced = true
                            }
                        }
                        
                        Button("Microcontroller") {
                            spawnEntity(fileName: "MicrocontrollerM")
                        }
                        
                        Button("Battery") {
                            spawnEntityWithCallback(fileName: "Battery5") {
                                if currentStepIndex == 3 {
                                    batterySpawned = true
                                }
                            }
                        }
                        
                        Button("Bulb") {
                            spawnEntityWithCallback(fileName: "Bulb") {
                                if currentStepIndex == 9 {
                                    bulbSpawned = true
                                }
                            }
                        }
                        
                        Button("Wire") {
                            spawnEntityWithCallback(fileName: "Wire4") {
                                if currentStepIndex == 5 {
                                    wireSpawned = true
                                }
                            }
                        }
                        
                        Button("Switch") {
                            spawnEntityWithCallback(fileName: "switch") {
                                if currentStepIndex == 7 {
                                    switchSpawned = true
                                }
                            }
                        }
                    }
                    .buttonStyle(TutorialButtonStyle())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 20)
                    
                    Spacer()
                }
                .zIndex(998)
            }
            
            VStack {
                Spacer()
                
                if connectionManager.isPoweredOn {
                    Text("⚡ Power On - Circuit Complete")
                        .padding(8)
                        .background(Color.yellow.opacity(0.8))
                        .cornerRadius(8)
                        .padding(.bottom, 10)
                }
                
                if selectionManager.selectedEntity != nil {
                    Text("✓ Selected - Drag or rotate with two fingers")
                        .padding(8)
                        .background(Color.green.opacity(0.7))
                        .cornerRadius(8)
                        .padding(.bottom, 20)
                }
            }
            .zIndex(997)
            
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
            
            if let message = surfaceMessage {
                VStack {
                    Text(message)
                        .padding()
                        .background(Color.red.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.top, 150)
                    
                    Spacer()
                }
                .zIndex(5000)
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
                .zIndex(2000)
            }
            
            if showFullscreenCircuitImage {
                FullscreenCircuitImagePopup(
                    imageName: currentStepIndex >= 13 ? "Image4" : "Image3",
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
            
            if currentStepIndex == 2 && tableSuccessfullyPlaced {
                ZStack {
                    Rectangle()
                        .stroke(borderColor, lineWidth: 10)
                        .ignoresSafeArea()
                        .animation(.easeInOut(duration: 0.3), value: borderColor)
                    
                    VStack {
                        Spacer()
                        
                        Text("Move back and adjust camera so all four corners of table are visible and hold for 3 seconds")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(borderColor.opacity(0.9))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
                            )
                            .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 5)
                            .padding(.bottom, 200)
                    }
                }
                .zIndex(1500)
            }
        } // End of ZStack
        .onChange(of: tableSuccessfullyPlaced) { _, newValue in
            if currentStepIndex == 2 && newValue {
                checkTableCorners()
            }
        }
        
        .onChange(of: wireSpawned) { _, newValue in
            if currentStepIndex == 5 && newValue {
                currentStepIndex += 1
                onDragEndCallback = {
                    self.checkPortConnection(entity1Name: "Wire4", entity2Name: "Battery5", stepIndex: 6)
                }
            }
        }
        .onChange(of: switchSpawned) { _, newValue in
            if currentStepIndex == 7 && newValue {
                currentStepIndex += 1
                onDragEndCallback = {
                    self.checkPortConnection(entity1Name: "switch", entity2Name: "Wire4", stepIndex: 8)
                }
            }
        }
        .onChange(of: bulbSpawned) { _, newValue in
            if currentStepIndex == 9 && newValue {
                currentStepIndex += 1
                onDragEndCallback = {
                    self.checkPortConnection(entity1Name: "Bulb", entity2Name: "switch", stepIndex: 10)
                }
            }
        }
        .onChange(of: connectionManager.isPoweredOn) { _, newValue in
            if currentStepIndex == 11 && newValue && switchToggled {
                currentStepIndex += 1
                onSwitchToggleCallback = nil  // Clear callback
            }
        }
        .onChange(of: batterySpawned) { _, newValue in
            if currentStepIndex == 3 && newValue {
                currentStepIndex += 1
                
                spawnTutorialMarker(x: 0.2, y: 0.06, z: 0)
                
                checkingMarkerPosition = true
                onDragEndCallback = {
                    if self.checkingMarkerPosition {
                        self.checkEntityOnMarker(entityNameContains: "Battery5") {
                            self.currentStepIndex += 1
                        }
                    }
                }
            }
        }
    }
    
    // Delete Entity
    
    
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
    
    // Prebuilt Circuit Spawner
    
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
        
        loadAndPlace(fileName: "MicrocontrollerM", xPos: -0.039, zPos: -0.18, rotationY: .pi * 2)
        loadAndPlace(fileName: "Battery5",          xPos:  0.320, zPos:  0.037)
        loadAndPlace(fileName: "Wire4",             xPos:  0.148, zPos:  0.036)
        loadAndPlace(fileName: "Wire4",             xPos: -0.141, zPos:  0.009)
        loadAndPlace(fileName: "Wire4",             xPos: -0.226, zPos:  0.058)
        loadAndPlace(fileName: "Wire4",             xPos: -0.142, zPos:  0.104)
        loadAndPlace(fileName: "Bulb",              xPos: -0.272, zPos:  0.009, rotationY: .pi/2)
        loadAndPlace(fileName: "Bulb",              xPos: -0.358, zPos:  0.058, rotationY: .pi/2)
        loadAndPlace(fileName: "Bulb",              xPos: -0.274, zPos:  0.104, rotationY: .pi/2)
        
        let allWrappers = table.children.filter { $0.name == "DraggableWrapper" }
        connectionManager.checkConnections(entities: allWrappers, selectionManager: selectionManager)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let mcWrapper = allWrappers.first(where: { wrapper in
                wrapper.children.first(where: { $0.name != "SelectionHighlight" })?.name.contains("MicrocontrollerM") == true
            }) {
                selectionManager.selectEntity(mcWrapper)
            }
        }
    }
    
    // Table Corner Detection
    
    func checkTableCorners() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            guard currentStepIndex == 2 else {
                timer.invalidate()
                return
            }
            
            guard let table = tableEntity,
                  let arView = ARViewContainer.sharedARView else { return }
            
            let tableWidth: Float = 1.0
            let tableDepth: Float = 0.5
            
            let corners = [
                SIMD3<Float>(-tableWidth/2, 0, -tableDepth/2),  // Top-left
                SIMD3<Float>(tableWidth/2, 0, -tableDepth/2),   // Top-right
                SIMD3<Float>(-tableWidth/2, 0, tableDepth/2),   // Bottom-left
                SIMD3<Float>(tableWidth/2, 0, tableDepth/2)     // Bottom-right
            ]
            
            let worldCorners = corners.map { table.convert(position: $0, to: nil) }
            
            let screenSize = arView.bounds.size
            var screenCorners: [CGPoint] = []
            
            for worldPos in worldCorners {
                if let screenPos = arView.project(worldPos) {
                    screenCorners.append(screenPos)
                }
            }
            
            guard screenCorners.count == 4 else {
                borderColor = .red
                greenBorderStartTime = nil
                return
            }
            
            let margin: CGFloat = 20
            var allCornersVisible = true
            
            for corner in screenCorners {
                let isVisible = corner.x >= margin &&
                corner.x <= screenSize.width - margin &&
                corner.y >= margin &&
                corner.y <= screenSize.height - margin
                
                if !isVisible {
                    allCornersVisible = false
                    break
                }
            }
            
            if allCornersVisible {
                borderColor = .green
                
                if greenBorderStartTime == nil {
                    greenBorderStartTime = Date()
                }
                
                if let startTime = greenBorderStartTime,
                   Date().timeIntervalSince(startTime) >= 3.0 {
                    tableCornersVisible = true
                    currentStepIndex += 1
                    timer.invalidate()
                }
            } else {
                borderColor = .red
                greenBorderStartTime = nil
            }
        }
    }
    
    // Generic Marker System
    
    func spawnTutorialMarker(
        x: Float,
        y: Float,
        z: Float,
        size: Float = 0.1
    ) {
        guard let table = tableEntity else { return }
        
        let pos = SIMD3<Float>(x, y, z)
        markerPosition = pos
        checkingMarkerPosition = true
        
        let marker = ModelEntity(
            mesh: .generateBox(size: size),
            materials: [
                SimpleMaterial(
                    color: .red.withAlphaComponent(0.8),
                    isMetallic: false
                )
            ]
        )
        
        marker.name = "TutorialMarker"
        marker.position = pos
        table.addChild(marker)
    }
    
    func removeTutorialMarker() {
        guard let table = tableEntity else { return }
        
        table.findEntity(named: "TutorialMarker")?.removeFromParent()
        markerPosition = nil
        checkingMarkerPosition = false
        onDragEndCallback = nil
    }
    
    func checkEntityOnMarker(
        entityNameContains name: String,
        threshold: Float = 0.15,
        onSuccess: () -> Void
    ) {
        guard let table = tableEntity,
              let markerPos = markerPosition else { return }
        
        let matches = table.children.filter { wrapper in
            wrapper.children.first(where: { $0.name != "SelectionHighlight" })?.name.contains(name) == true
        }
        
        for entity in matches {
            let distance = simd_distance(entity.position, markerPos)
            if distance < threshold {
                onSuccess()
                removeTutorialMarker()
                return
            }
        }
    }
    
    func checkPortConnection(entity1Name: String, entity2Name: String, stepIndex: Int) {
        guard currentStepIndex == stepIndex else { return }
        guard let table = tableEntity else { return }
        
        let entity1 = table.children.first { wrapper in
            wrapper.children.first(where: { $0.name != "SelectionHighlight" })?.name.contains(entity1Name) == true
        }
        
        let entity2 = table.children.first { wrapper in
            wrapper.children.first(where: { $0.name != "SelectionHighlight" })?.name.contains(entity2Name) == true
        }
        
        guard let entity1 = entity1, let entity2 = entity2 else { return }
        
        func findAllMainPorts(in entity: Entity) -> [Entity] {
            var ports: [Entity] = []
            if entity.name == "mainPort" {
                ports.append(entity)
            }
            for child in entity.children {
                ports.append(contentsOf: findAllMainPorts(in: child))
            }
            return ports
        }
        
        let entity1Ports = findAllMainPorts(in: entity1)
        let entity2Ports = findAllMainPorts(in: entity2)
        
        let connectionThreshold: Float = 0.02  // 2cm - same as circuit connection threshold
        
        for port1 in entity1Ports {
            for port2 in entity2Ports {
                let port1WorldPos = port1.position(relativeTo: nil)
                let port2WorldPos = port2.position(relativeTo: nil)
                let distance = simd_distance(port1WorldPos, port2WorldPos)
                
                if distance < connectionThreshold {
                    print("✅ \(entity1Name) connected to \(entity2Name)! Distance: \(distance)m")
                    currentStepIndex += 1
                    onDragEndCallback = nil  // Clear callback
                    return
                }
            }
        }
    }
}

// Instruction Card Component

struct InstructionCard: View {
    let number: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                color.opacity(0.8),
                                color.opacity(0.6)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                
                Text(number)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            .shadow(color: color.opacity(0.4), radius: 4, x: 0, y: 2)
            
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(color.opacity(0.3), lineWidth: 1.5)
        )
    }
}

// Button Style

struct TutorialButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: 160, height: 44)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.2, green: 0.3, blue: 0.5).opacity(configuration.isPressed ? 0.7 : 0.9),
                                    Color(red: 0.15, green: 0.25, blue: 0.45).opacity(configuration.isPressed ? 0.7 : 0.9)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
            )
            .shadow(color: .black.opacity(configuration.isPressed ? 0.2 : 0.3), radius: configuration.isPressed ? 4 : 8, x: 0, y: configuration.isPressed ? 2 : 4)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// Clear Button Style

struct ClearButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: 160, height: 44)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.gray.opacity(configuration.isPressed ? 0.5 : 0.7),
                                    Color.gray.opacity(configuration.isPressed ? 0.4 : 0.6)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
            )
            .shadow(color: .black.opacity(configuration.isPressed ? 0.2 : 0.3), radius: configuration.isPressed ? 4 : 8, x: 0, y: configuration.isPressed ? 2 : 4)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}


// Fullscreen Circuit Image Popup

struct FullscreenCircuitImagePopup: View {
    let imageName: String
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            VStack(spacing: 20) {
                HStack {
                    Image(systemName: "lightbulb.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.yellow)
                    
                    Text("Target Circuit")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 20)
                
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .cornerRadius(12)
                    .shadow(color: .blue.opacity(0.5), radius: 20, x: 0, y: 10)
                    .padding(20)
            }
            .padding(.vertical, 40)
        }
    }
}
