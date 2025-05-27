import SwiftUI

struct SplashView: View {
    @State private var animate = false
    @Binding var isActive: Bool
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            HStack(spacing: 0) {
                Text("SafeRelay")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .mask(
                            Text("SafeRelay")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                        )
                    )
                Text(" ")
                Text("+")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple, Color.pink]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .mask(
                            Text("+")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                        )
                    )
            }
            .scaleEffect(animate ? 1 : 0.7)
            .opacity(animate ? 1 : 0)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    animate = true
                }
                // Переход на главный экран через 1.5 сек
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        isActive = false
                    }
                }
            }
        }
    }
}

#Preview {
    SplashView(isActive: .constant(true))
}
