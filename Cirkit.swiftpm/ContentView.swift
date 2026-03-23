import SwiftUI

struct ContentView: View {
    @State private var showTutorial = false
    @State private var showFreeplay = false
    @State private var showLibrary = false
    @State private var showSmartLight = false
    @State private var showAutoLight = false
    @State private var arSessionID = UUID()
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.15, blue: 0.25),
                        Color(red: 0.15, green: 0.2, blue: 0.3)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 50) {
                    VStack(spacing: 20) {
                        Image("Image2")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .padding(20)
                            .background(
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            gradient: Gradient(colors: [
                                                Color.white.opacity(0.3),
                                                Color.white.opacity(0.1)
                                            ]),
                                            center: .center,
                                            startRadius: 10,
                                            endRadius: 60
                                        )
                                    )
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.4), lineWidth: 3)
                            )
                            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                        
                        Text("Welcome to Cirkit")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        
                        Text("Build AR circuits with ease")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top, 80)
                    
                    VStack(spacing: 20) {
                        ZStack(alignment: .trailing) {
                            Button(action: {
                                arSessionID = UUID()
                                showTutorial = true
                            }) {
                                HStack(spacing: 15) {
                                    Image(systemName: "book.fill")
                                        .font(.system(size: 24))
                                    Text("Tutorial")
                                        .font(.system(size: 20, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(width: 280, height: 60)
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 16)
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
                                        
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color.white.opacity(0.3),
                                                        Color.white.opacity(0.1)
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 2
                                            )
                                    }
                                )
                                .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
                            }
                            
                            StartHereHint()
                                .offset(x: 220)
                        }
                        
                        Button(action: {
                            showLibrary = true
                        }) {
                            HStack(spacing: 15) {
                                Image(systemName: "books.vertical.fill")
                                    .font(.system(size: 24))
                                Text("Library")
                                    .font(.system(size: 20, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(width: 280, height: 60)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color(red: 0.3, green: 0.2, blue: 0.4).opacity(0.95),
                                                    Color(red: 0.25, green: 0.15, blue: 0.35).opacity(0.95)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.white.opacity(0.3),
                                                    Color.white.opacity(0.1)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                }
                            )
                            .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
                        }
                        
                        Button(action: {
                            arSessionID = UUID()
                            showFreeplay = true
                        }) {
                            HStack(spacing: 15) {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 24))
                                Text("Freeplay")
                                    .font(.system(size: 20, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(width: 280, height: 60)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color(red: 0.2, green: 0.5, blue: 0.3).opacity(0.95),
                                                    Color(red: 0.15, green: 0.45, blue: 0.25).opacity(0.95)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.white.opacity(0.3),
                                                    Color.white.opacity(0.1)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                }
                            )
                            .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
                        }
                    }
                    
                    Spacer()
                }
            }
            .navigationDestination(isPresented: $showTutorial) {
                TutorialView()
                    .id(arSessionID)
            }
            .navigationDestination(isPresented: $showFreeplay) {
                ARTableView()
                    .id(arSessionID)
            }
            .sheet(isPresented: $showLibrary) {
                LibraryView(
                    onSelectSmartLight: {
                        showLibrary = false
                        arSessionID = UUID()
                        showSmartLight = true
                    },
                    onSelectAutoLight: {
                        showLibrary = false
                        arSessionID = UUID()
                        showAutoLight = true
                    }
                )
            }
            .navigationDestination(isPresented: $showSmartLight) {
                SmartLightView()
                    .id(arSessionID)
            }
            .navigationDestination(isPresented: $showAutoLight) {
                AutoLightView()
                    .id(arSessionID)
            }
        }
    }
}

// Library View

struct LibraryView: View {
    @Environment(\.dismiss) var dismiss
    let onSelectSmartLight: () -> Void
    let onSelectAutoLight: () -> Void
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.15, blue: 0.25),
                    Color(red: 0.15, green: 0.2, blue: 0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Text("Project Library")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(20)
                
                ScrollView {
                    VStack(spacing: 15) {
                        projectCard(
                            title: "Smart Light Control System",
                            description: "Use push button to control lights",
                            icon: "lightbulb.2.fill",
                            color: .cyan,
                            isAvailable: true,
                            action: {
                                onSelectSmartLight()
                            }
                        )
                        
                        projectCard(
                            title: "Automatic Light Sensor Lights",
                            description: "Lights turn on automatically when it's dark",
                            icon: "light.beacon.max.fill",
                            color: .yellow,
                            isAvailable: true,
                            action: {
                                onSelectAutoLight()
                            }
                        )
                        
                        projectCardComingSoon(title: "Automatic Door", icon: "door.left.hand.open")
                        projectCardComingSoon(title: "Security Alarm", icon: "bell.fill")
                        projectCardComingSoon(title: "Temperature Monitor", icon: "thermometer")
                        projectCardComingSoon(title: "Motion Detector", icon: "figure.walk")
                    }
                    .padding(20)
                }
            }
        }
    }
    
    func projectCard(title: String, description: String, icon: String, color: Color, isAvailable: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(color)
                    .frame(width: 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(description)
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
    }
    
    func projectCardComingSoon(title: String, icon: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(.white.opacity(0.3))
                .frame(width: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                
                Text("Coming Soon")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.3))
            }
            
            Spacer()
            
            Image(systemName: "lock.fill")
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(15)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// Tutorial Popup Component

struct TutorialPopup: View {
    let imageName: String  // Image or video placeholder name
    let description: String
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .clipped()
                    .background(Color.black.opacity(0.2))
                
                VStack(spacing: 20) {
                    Text(description)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                    
                    Button(action: onContinue) {
                        Text("Continue")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.green,
                                        Color.green.opacity(0.85)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: Color.green.opacity(0.5), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
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
            }
            .frame(width: 340)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
        }
    }
}

// Start Here Hint Component

struct StartHereHint: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.left")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.yellow)
            
            Text("Start by pressing here")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.yellow.opacity(0.5), lineWidth: 1.5)
                )
        )
        .shadow(color: .yellow.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}
