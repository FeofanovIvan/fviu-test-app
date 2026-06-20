import SwiftUI

struct PaywallProductRow: View {
    let product: PaywallProduct
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 9) {
                    Text("\(product.title) \(product.priceText)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AppColors.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Text(product.subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color(red: 0.376, green: 0.376, blue: 0.376))
                }

                Spacer()

                if let badgeText = product.badgeText {
                    Text(badgeText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .allowsTightening(true)
                        .frame(width: 102, height: 25)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.596, green: 0.776, blue: 0.969),
                                    Color(red: 0.922, green: 0.357, blue: 0.573)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: Capsule()
                        )
                }
            }
            .padding(.leading, 24)
            .padding(.trailing, 16)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(Color.clear, in: RoundedRectangle(cornerRadius: 24))
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(
                        isSelected
                            ? LinearGradient(
                                colors: [
                                    Color(red: 0.596, green: 0.776, blue: 0.969),
                                    Color(red: 0.922, green: 0.357, blue: 0.573)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            : LinearGradient(
                                colors: [Color.white.opacity(0.3), Color.white.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                        lineWidth: isSelected ? 1.6 : 1
                    )
            }
        }
        .buttonStyle(.plain)
    }
}
