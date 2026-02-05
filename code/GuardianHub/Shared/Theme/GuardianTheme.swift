import SwiftUI

// MARK: - Guardian Theme Colors

/// A cohesive design system for GuardianHub with vibrant gradients and modern styling
enum GuardianTheme {
    
    // MARK: - Section Colors
    
    enum SectionColor {
        case dashboard
        case identityCheck
        case webAuditor
        case privacyGuard
        case passwordLab
        
        var gradient: LinearGradient {
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        var gradientColors: [Color] {
            switch self {
            case .dashboard:
                return [Color(hex: 0x667EEA), Color(hex: 0x764BA2)]
            case .identityCheck:
                return [Color(hex: 0xF093FB), Color(hex: 0xF5576C)]
            case .webAuditor:
                return [Color(hex: 0x4FACFE), Color(hex: 0x00F2FE)]
            case .privacyGuard:
                return [Color(hex: 0x43E97B), Color(hex: 0x38F9D7)]
            case .passwordLab:
                return [Color(hex: 0xFA709A), Color(hex: 0xFEE140)]
            }
        }
        
        var primaryColor: Color {
            gradientColors[0]
        }
        
        var secondaryColor: Color {
            gradientColors[1]
        }
    }
    
    // MARK: - Status Colors
    
    enum StatusGradient {
        case success
        case warning
        case danger
        case neutral
        
        var gradient: LinearGradient {
            LinearGradient(
                colors: colors,
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        
        var colors: [Color] {
            switch self {
            case .success:
                return [Color(hex: 0x11998E), Color(hex: 0x38EF7D)]
            case .warning:
                return [Color(hex: 0xF2994A), Color(hex: 0xF2C94C)]
            case .danger:
                return [Color(hex: 0xEB3349), Color(hex: 0xF45C43)]
            case .neutral:
                return [Color(hex: 0x8E9AAF), Color(hex: 0xCBC0D3)]
            }
        }
        
        var primaryColor: Color {
            colors[0]
        }
    }
    
    // MARK: - Password Strength Colors
    
    static func strengthGradient(for category: PasswordStrengthCategory) -> LinearGradient {
        let colors: [Color]
        switch category {
        case .veryWeak:
            colors = [Color(hex: 0xEB3349), Color(hex: 0xF45C43)]
        case .weak:
            colors = [Color(hex: 0xF2994A), Color(hex: 0xF2C94C)]
        case .fair:
            colors = [Color(hex: 0xF7971E), Color(hex: 0xFFD200)]
        case .strong:
            colors = [Color(hex: 0x11998E), Color(hex: 0x38EF7D)]
        }
        return LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
    }
    
    static func strengthColor(for category: PasswordStrengthCategory) -> Color {
        switch category {
        case .veryWeak: return Color(hex: 0xEB3349)
        case .weak: return Color(hex: 0xF2994A)
        case .fair: return Color(hex: 0xF7971E)
        case .strong: return Color(hex: 0x11998E)
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

// MARK: - Styled Card Modifier

struct GlassCardStyle: ViewModifier {
    var cornerRadius: CGFloat = 20
    var showBorder: Bool = true
    
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
            }
            .overlay {
                if showBorder {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                }
            }
    }
}

struct GradientCardStyle: ViewModifier {
    let gradient: LinearGradient
    var cornerRadius: CGFloat = 20
    var intensity: Double = 0.15
    
    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.background)
                    
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(gradient.opacity(intensity))
                }
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(gradient.opacity(0.3), lineWidth: 1)
            }
    }
}

// MARK: - View Extensions

extension View {
    func glassCard(cornerRadius: CGFloat = 20, showBorder: Bool = true) -> some View {
        modifier(GlassCardStyle(cornerRadius: cornerRadius, showBorder: showBorder))
    }
    
    func gradientCard(_ gradient: LinearGradient, cornerRadius: CGFloat = 20, intensity: Double = 0.15) -> some View {
        modifier(GradientCardStyle(gradient: gradient, cornerRadius: cornerRadius, intensity: intensity))
    }
    
    func sectionCard(_ section: GuardianTheme.SectionColor, cornerRadius: CGFloat = 20) -> some View {
        modifier(GradientCardStyle(gradient: section.gradient, cornerRadius: cornerRadius))
    }
}

// MARK: - Gradient Icon Background

struct GradientIconBackground: View {
    let gradient: LinearGradient
    let shadowColor: Color
    var size: CGFloat = 40
    
    init(gradient: LinearGradient, shadowColor: Color = .clear, size: CGFloat = 40) {
        self.gradient = gradient
        self.shadowColor = shadowColor
        self.size = size
    }
    
    var body: some View {
        Circle()
            .fill(gradient)
            .frame(width: size, height: size)
            .shadow(color: shadowColor.opacity(0.4), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Animated Gradient Ring

struct AnimatedGradientRing: View {
    let progress: Double
    let gradient: LinearGradient
    var lineWidth: CGFloat = 8
    
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Color.secondary.opacity(0.15), lineWidth: lineWidth)
            
            // Gradient progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    gradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.8, dampingFraction: 0.7), value: animatedProgress)
        }
        .onAppear {
            animatedProgress = progress
        }
        .onChange(of: progress) { _, newValue in
            animatedProgress = newValue
        }
    }
}

// MARK: - Animated Progress Bar

struct AnimatedGradientBar: View {
    let progress: Double
    let gradient: LinearGradient
    var height: CGFloat = 10
    var cornerRadius: CGFloat = 5
    
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.secondary.opacity(0.15))
                
                // Gradient progress
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(gradient)
                    .frame(width: geometry.size.width * animatedProgress)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animatedProgress)
            }
        }
        .frame(height: height)
        .onAppear {
            animatedProgress = progress
        }
        .onChange(of: progress) { _, newValue in
            animatedProgress = newValue
        }
    }
}

// MARK: - Pulsing Indicator

struct PulsingDot: View {
    let color: Color
    var size: CGFloat = 8
    
    @State private var isPulsing = false
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .overlay {
                Circle()
                    .stroke(color.opacity(0.5), lineWidth: 2)
                    .scaleEffect(isPulsing ? 2 : 1)
                    .opacity(isPulsing ? 0 : 1)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    isPulsing = true
                }
            }
    }
}

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.3),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.6)
                    .offset(x: phase * geometry.size.width * 1.6 - geometry.size.width * 0.3)
                }
                .mask(content)
            }
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Metric Badge

struct MetricBadge: View {
    let value: String
    let label: String
    let gradient: LinearGradient
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(gradient)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    let subtitle: String?
    let gradient: LinearGradient
    
    init(title: String, subtitle: String? = nil, gradient: LinearGradient) {
        self.title = title
        self.subtitle = subtitle
        self.gradient = gradient
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.title2.weight(.bold))
                .foregroundStyle(gradient)
            
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
