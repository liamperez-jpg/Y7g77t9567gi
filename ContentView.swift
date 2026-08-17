import SwiftUI

enum Phase {
    case mockup
    case flashBlackOn1, flashBlackOff1
    case flashBlackOn2, flashBlackOff2
    case tone
    case panic
    case appleLogo
    case done
}

struct ContentView: View {
    @State private var phase: Phase = .mockup
    private let tone = ToneGenerator()

    var body: some View {
        ZStack {
            switch phase {
            case .mockup:
                MockupHomeScreenView()
            case .flashBlackOn1, .flashBlackOn2:
                Color.black.ignoresSafeArea()
            case .flashBlackOff1, .flashBlackOff2:
                MockupHomeScreenView()
            case .tone:
                Color.black.ignoresSafeArea()
            case .panic:
                KernelPanicView()
            case .appleLogo:
                AppleBootView()
            case .done:
                Color.black.ignoresSafeArea()
            }
        }
        .onAppear { runSequence() }
    }

    private func runSequence() {
        Task {
            // 1. Show the iPad mockup home screen
            await wait(2.0)

            // 2. Flash black, twice
            phase = .flashBlackOn1
            await wait(0.25)
            phase = .flashBlackOff1
            await wait(0.2)
            phase = .flashBlackOn2
            await wait(0.25)
            phase = .flashBlackOff2
            await wait(0.2)

            // 3. High-pitch tone for 3 seconds over a black screen
            phase = .tone
            await withCheckedContinuation { continuation in
                tone.playFor(seconds: 3.0, frequency: 15500) {
                    continuation.resume()
                }
            }

            // 4. Kernel panic mimic screen
            phase = .panic
            await wait(4.0)

            // 5. Apple boot logo
            phase = .appleLogo
            await wait(2.0)

            // 6. Close the app
            phase = .done
            await wait(0.3)
            exit(0)
        }
    }

    private func wait(_ seconds: Double) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}

// MARK: - Fake iPad home screen mockup

struct MockupHomeScreenView: View {
    private let rows = 5
    private let columns = 4
    private let iconNames = [
        "message.fill", "phone.fill", "safari.fill", "camera.fill",
        "photo.fill", "gearshape.fill", "mail.fill", "calendar",
        "music.note", "map.fill", "note.text", "clock.fill",
        "cloud.sun.fill", "gamecontroller.fill", "app.fill", "folder.fill",
        "cart.fill", "book.fill", "tv.fill", "wallet.pass.fill"
    ]

    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.15, blue: 0.35), Color(red: 0.02, green: 0.02, blue: 0.1)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            VStack {
                statusBar
                Spacer().frame(height: 24)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: columns), spacing: 28) {
                    ForEach(0..<iconNames.count, id: \.self) { i in
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: iconNames[i])
                                        .font(.system(size: 26))
                                        .foregroundColor(.white)
                                )
                            Text("App \(i + 1)")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.85))
                        }
                    }
                }
                .padding(.horizontal, 24)
                Spacer()
                dock
                    .padding(.bottom, 20)
            }
        }
    }

    private var statusBar: some View {
        HStack {
            Text(currentTime())
                .font(.system(size: 14, weight: .semibold))
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "wifi")
                Image(systemName: "battery.75")
            }
            .font(.system(size: 14))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var dock: some View {
        HStack(spacing: 30) {
            ForEach(["phone.fill", "safari.fill", "message.fill", "music.note"], id: \.self) { name in
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 55, height: 55)
                    .overlay(Image(systemName: name).foregroundColor(.white))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 30)
    }

    private func currentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: Date())
    }
}

// MARK: - Kernel panic mimic screen

struct KernelPanicView: View {
    // Purely cosmetic, fictional log lines styled after low-level crash dumps.
    // Not a reproduction of any real device's actual panic string.
    private let logLines = [
        "panic(cpu 0 caller 0xfffffff01a2b3c4d): \"userspace watchdog timeout\"",
        "Debugger message: panic",
        "Kernel version: Darwin Kernel Version (mock build)",
        "Backtrace (CPU 0), Frame : Return Address",
        "0xfffffe000a1b2c30 : 0xfffffe000a001234",
        "0xfffffe000a1b2c60 : 0xfffffe000a005678",
        "0xfffffe000a1b2ca0 : 0xfffffe000a009abc",
        "BSD process name corresponding to current thread: mockd",
        "Mach snapshot state unavailable",
        "Preparing to write panic log — do not power off device"
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 8) {
                Text("Kernel Panic")
                    .font(.system(.title2, design: .monospaced)).bold()
                    .foregroundColor(.white)
                    .padding(.bottom, 6)
                ForEach(logLines, id: \.self) { line in
                    Text(line)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Apple boot logo screen

struct AppleBootView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Image(systemName: "apple.logo")
                .font(.system(size: 90))
                .foregroundColor(.white)
        }
    }
}
