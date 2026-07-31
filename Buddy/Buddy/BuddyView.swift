import SwiftUI

struct BuddyView: View {
    @State private var isHovering = false
    @State private var isWaving = false

    var body: some View {
        VStack(spacing: 8) {
            if isHovering {
                Text("Hi! I'm Buddy 👋")
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(.regularMaterial)
                    )
                    .transition(
                        .move(edge: .bottom)
                        .combined(with: .opacity)
                    )
            }

            ZStack {
                Circle()
                    .fill(.blue.gradient)
                    .frame(width: 130, height: 130)
                    .shadow(
                        color: .black.opacity(0.2),
                        radius: 8,
                        y: 5
                    )

                VStack(spacing: 8) {
                    Text(isWaving ? "👋" : "🤖")
                        .font(.system(size: 58))

                    Text("Buddy")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .scaleEffect(isHovering ? 1.06 : 1)
            .animation(
                .spring(response: 0.3),
                value: isHovering
            )
            .onTapGesture {
                isWaving = true

                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    isWaving = false
                }
            }
        }
        .frame(width: 220, height: 220)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation {
                isHovering = hovering
            }
        }
    }
}

#Preview {
    BuddyView()
        .frame(width: 220, height: 220)
        .background(.gray.opacity(0.4))
}
