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
            await wait(2.0)

            phase = .flashBlackOn1
            await wait(0.25)
            phase = .flashBlackOff1
            await wait(0.2)
            phase = .flashBlackOn2
            await wait(0.25)
            phase = .flashBlackOff2
            await wait(0.2)

            phase = .tone
            await withCheckedContinuation { continuation in
                tone.playFor(seconds: 3.0, frequency: 15500) {
                    continuation.resume()
                }
            }

            phase = .panic
            await wait(5.5)

            phase = .appleLogo
            await wait(2.0)

            phase = .done
            await wait(0.3)
            exit(0)
        }
    }

    private func wait(_ seconds: Double) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}

// MARK: - Realistic iPhone home screen mockup (portrait only)

struct MockupHomeScreenView: View {
    private let iconNames = [
        "message.fill", "phone.fill", "safari.fill", "camera.fill",
        "photo.fill", "gearshape.fill", "mail.fill", "calendar",
        "music.note", "map.fill", "note.text", "clock.fill",
        "cloud.sun.fill", "gamecontroller.fill", "app.fill", "folder.fill",
        "cart.fill", "book.fill", "tv.fill", "wallet.pass.fill",
        "figure.walk", "chart.bar.fill", "bolt.fill", "shield.fill"
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                // Procedural wallpaper — soft depth-of-field style gradient mesh,
                // not a reproduction of any real device wallpaper asset.
                wallpaper

                VStack(spacing: 0) {
                    statusBar
                        .padding(.top, geo.safeAreaInsets.top > 0 ? 8 : 20)

                    Spacer().frame(height: 28)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 22) {
                        ForEach(0..<iconNames.count, id: \.self) { i in
                            VStack(spacing: 6) {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: iconGradient(for: i),
                                            startPoint: .topLeading, endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 58, height: 58)
                                    .overlay(
                                        Image(systemName: iconNames[i])
                                            .font(.system(size: 24, weight: .medium))
                                            .foregroundColor(.white)
                                    )
                                    .shadow(color: .black.opacity(0.25), radius: 3, y: 2)
                                Text("App")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.6), radius: 2)
                            }
                        }
                    }
                    .padding(.horizontal, 22)

                    Spacer()

                    dock
                        .padding(.bottom, geo.safeAreaInsets.bottom > 0 ? 8 : 20)
                }

                // Dynamic-island-style pill at the top, purely cosmetic
                Capsule()
                    .fill(Color.black)
                    .frame(width: 110, height: 32)
                    .padding(.top, 11)
            }
            .ignoresSafeArea()
        }
    }

    private var wallpaper: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.08, blue: 0.22),
                    Color(red: 0.15, green: 0.1, blue: 0.35),
                    Color(red: 0.35, green: 0.15, blue: 0.3)
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [Color.white.opacity(0.18), Color.clear],
                center: .init(x: 0.75, y: 0.15), startRadius: 10, endRadius: 320
            )
            RadialGradient(
                colors: [Color.orange.opacity(0.22), Color.clear],
                center: .init(x: 0.2, y: 0.85), startRadius: 20, endRadius: 380
            )
        }
        .ignoresSafeArea()
    }

    private func iconGradient(for index: Int) -> [Color] {
        let palettes: [[Color]] = [
            [.blue, .cyan], [.pink, .purple], [.orange, .red],
            [.green, .mint], [.indigo, .blue], [.yellow, .orange]
        ]
        return palettes[index % palettes.count]
    }

    private var statusBar: some View {
        HStack {
            Text(currentTime())
                .font(.system(size: 15, weight: .semibold))
            Spacer()
            HStack(spacing: 5) {
                Image(systemName: "cellularbars")
                Image(systemName: "wifi")
                Image(systemName: "battery.75")
            }
            .font(.system(size: 14))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 24)
    }

    private func currentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: Date())
    }

    private var dock: some View {
        HStack(spacing: 24) {
            ForEach(["phone.fill", "safari.fill", "message.fill", "music.note"], id: \.self) { name in
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 56, height: 56)
                    .overlay(Image(systemName: name).font(.system(size: 22)).foregroundColor(.white))
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28))
        .padding(.horizontal, 24)
    }
}

// MARK: - Kernel panic mimic — live-scrolling terminal log

struct KernelPanicView: View {
    @State private var lines: [String] = []
    @State private var cursorVisible = true
    @State private var printTask: Task<Void, Never>?
    @State private var cursorTimer: Timer?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("panic(cpu 0 caller 0xfffffff01a2b3c4d): \"userspace watchdog timeout\"")
                            .font(.system(.footnote, design: .monospaced)).bold()
                            .foregroundColor(.white)
                            .padding(.bottom, 6)
                            .id("top")

                        ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(.white.opacity(0.88))
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        HStack(spacing: 2) {
                            Text(">")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(.white.opacity(0.88))
                            Rectangle()
                                .fill(Color.white.opacity(cursorVisible ? 0.9 : 0))
                                .frame(width: 7, height: 12)
                        }
                        .id("cursor")
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .onChange(of: lines.count) { _ in
                    withAnimation(.linear(duration: 0.1)) {
                        scrollProxy.scrollTo("cursor", anchor: .bottom)
                    }
                }
            }
        }
        .onAppear { startPrinting() }
        .onDisappear {
            printTask?.cancel()
            cursorTimer?.invalidate()
        }
    }

    private func startPrinting() {
        cursorTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            cursorVisible.toggle()
        }
        printTask = Task {
            var counter = 0
            while !Task.isCancelled {
                lines.append(nextLogLine(counter))
                counter += 1
                if lines.count > 60 { lines.removeFirst(lines.count - 60) }
                try? await Task.sleep(nanoseconds: UInt64.random(in: 60_000_000...160_000_000))
            }
        }
    }

    // Procedurally generated, plausible-looking crash log text.
    // Not a reproduction of any real device's actual panic output.
    private func nextLogLine(_ i: Int) -> String {
        let templates: [(Int) -> String] = [
            { n in "Backtrace (CPU 0), Frame : Return Address" },
            { n in String(format: "0xfffffe%06x : 0xfffffe%06x", Int.random(in: 0...0xFFFFFF), Int.random(in: 0...0xFFFFFF)) },
            { n in "BSD process name corresponding to current thread: mockd" },
            { n in "Mach snapshot state unavailable" },
            { n in String(format: "R%d: 0x%08x  R%d: 0x%08x", n % 12, Int.random(in: 0...0xFFFFFFFF), (n+1) % 12, Int.random(in: 0...0xFFFFFFFF)) },
            { n in "Kernel Extensions in backtrace:" },
            { n in "com.apple.driver.watchdogd(1.0)[mock-uuid]::0xfffffe000a1b2c00->0xfffffe000a200000" },
            { n in "sysctl: kern.panic_diag_log unavailable" },
            { n in "Debugger message: panic" },
            { n in "Memory ID: 0x\(String(Int.random(in: 0...0xFFFFFF), radix: 16))" },
            { n in "Compressor Info: 0% of compressed pages limit" },
            { n in "Panicked task 0xfffffe0009f00000: 0 pages, 412 threads: pid 0: mockkernel" },
            { n in "thread_setrun, stack = 0x\(String(Int.random(in: 0...0xFFFFFF), radix: 16)), thread_id = \(Int.random(in: 100...9999))" },
            { n in "Preparing to write panic log — do not power off device" }
        ]
        return templates[i % templates.count](i)
    }
}

// MARK: - Apple boot logo screen

struct AppleBootView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Image(systemName: "apple.logo")
                .font(.system(size: 74))
                .foregroundColor(.white)
        }
    }
}
