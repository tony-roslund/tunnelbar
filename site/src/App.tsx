import {
  Check,
  Copy,
  History,
  Link2,
  Menu,
  Play,
  Square,
  Terminal,
} from "lucide-react";
import type { PointerEvent } from "react";

const flowSteps = [
  {
    label: "Paste",
    title: "Drop in the local URL",
    copy: "TunnelBar extracts the local origin and keeps the path, query, and fragment ready for the public link.",
    code: "http://localhost:3000",
  },
  {
    label: "Expose",
    title: "Start a tunnel",
    copy: "The native app starts the tunnel process and keeps it alive until you stop it.",
    code: "tunnel -> http://localhost:3000",
  },
  {
    label: "Share",
    title: "Copy the public URL",
    copy: "The generated public URL keeps any original route and lands on your clipboard.",
    code: "https://demo-tunnel.example",
  },
];

const featureRows = [
  ["Local only", "Only your local server is exposed by the tunnel process."],
  ["Route preserving", "A URL like http://localhost:3000/share/review keeps its route."],
  ["Visible lifecycle", "Active tunnels are shown in the menu bar and stop on quit."],
  ["Local history", "Recent tunnel mappings stay on your Mac."],
];

const recentLinks = [
  {
    local: "http://localhost:3000/share/review",
    public: "https://demo-tunnel.example/share/review",
    state: "active",
  },
  {
    local: "http://localhost:3001/invoices/preview",
    public: "https://brisk-river-demo.example/invoices/preview",
    state: "active",
  },
  {
    local: "http://localhost:3000/api/webhooks/test",
    public: "https://silent-lab-demo.example/api/webhooks/test",
    state: "stopped",
  },
];

function StatusDot({ tone = "accent" }: { tone?: "accent" | "ember" | "cyan" }) {
  const color = {
    accent: "bg-accent",
    ember: "bg-ember",
    cyan: "bg-cyanic",
  }[tone];

  return <span className={`size-2 rounded-full ${color}`} aria-hidden="true" />;
}

function updateGlowPosition(event: PointerEvent<HTMLDivElement>) {
  const rect = event.currentTarget.getBoundingClientRect();
  event.currentTarget.style.setProperty("--glow-x", `${event.clientX - rect.left}px`);
  event.currentTarget.style.setProperty("--glow-y", `${event.clientY - rect.top}px`);
}

export default function App() {
  return (
    <main className="isolate min-h-dvh overflow-x-hidden bg-paper font-sans text-ink">
      <div className="fixed inset-0 -z-10 bg-[radial-gradient(circle_at_50%_0%,rgba(216,255,95,0.12),transparent_34%),linear-gradient(180deg,rgba(255,255,255,0.05),transparent_42%)]" />
      <div className="fixed inset-0 -z-10 bg-[linear-gradient(rgba(244,241,232,0.035)_1px,transparent_1px),linear-gradient(90deg,rgba(244,241,232,0.035)_1px,transparent_1px)] bg-[size:48px_48px] [mask-image:linear-gradient(to_bottom,black,transparent_78%)]" />

      <header className="mx-auto flex w-full max-w-7xl items-center justify-between px-5 py-5 sm:px-8">
        <a href="#top" className="flex items-center" aria-label="TunnelBar home">
          <span className="brand-terminal-mark font-mono text-sm font-semibold text-accent">
            <span aria-hidden="true">% tunnelbar</span>
            <span className="brand-terminal-cursor" aria-hidden="true" />
          </span>
        </a>

        <nav className="hidden items-center gap-6 font-mono text-sm sm:flex">
          <a className="text-ink/62 hover:text-ink" href="#flow">
            <span className="text-accent">~/</span>
            flow
          </a>
          <a className="text-ink/62 hover:text-ink" href="#details">
            <span className="text-accent">~/</span>
            details
          </a>
        </nav>
      </header>

      <section id="top" className="mx-auto grid w-full max-w-7xl gap-10 px-5 pb-16 pt-8 sm:px-8 lg:grid-cols-[15fr_17fr] lg:items-center lg:pb-24 lg:pt-14">
        <div className="flex flex-col gap-8">
          <div className="flex w-fit items-center gap-2 rounded-full border border-line bg-ink/4 px-3 py-1.5 font-mono text-base text-ink/72 sm:text-sm">
            <StatusDot />
            native macOS tunnels
          </div>

          <div className="flex flex-col gap-5">
            <h1 className="max-w-[12ch] text-balance font-heading text-5xl font-semibold text-ink sm:text-6xl lg:text-7xl">
              Localhost, shipped to a URL.
            </h1>
            <p className="max-w-[58ch] text-pretty text-lg text-ink/68 sm:text-base">
              TunnelBar lives in your menu bar. Paste a localhost URL, start a temporary public tunnel, and get the shareable URL copied back. Routes like /share/review stay attached.
            </p>
          </div>

          <div className="flex flex-col gap-3 sm:flex-row">
            <a
              href="#status"
              className="inline-flex items-center justify-center rounded-md bg-accent px-4 py-3 text-base font-medium text-paper ring-1 ring-accent focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-accent sm:text-sm"
            >
              Download for Mac
            </a>
          </div>

        </div>

        <div className="relative min-w-0">
          <div className="absolute -inset-6 -z-10 rounded-[min(2vw,24px)] bg-accent/8 blur-3xl" />
          <div className="overflow-hidden rounded-[min(2vw,18px)] border border-ink/10 bg-[#171816] shadow-2xl shadow-black/50 outline-1 -outline-offset-1 outline-white/10">
            <div className="flex items-center justify-between border-b border-white/10 bg-[#20211e] px-4 py-3 font-mono text-base text-ink/70 sm:text-sm">
              <div className="flex items-center gap-2">
                <span className="size-3 rounded-full bg-[#ff5f57]" />
                <span className="size-3 rounded-full bg-[#ffbd2e]" />
                <span className="size-3 rounded-full bg-[#28c840]" />
              </div>
              <div className="flex items-center gap-4">
                <span>Sun 10:55 AM</span>
                <span className="flex items-center gap-2 text-ink">
                  <Menu className="size-4" aria-hidden="true" />
                  TunnelBar
                </span>
              </div>
            </div>

            <div className="relative bg-[linear-gradient(135deg,rgba(255,255,255,0.04),transparent_45%),#10110f] p-4 sm:p-8">
              <div className="mx-auto max-w-md rounded-xl border border-white/10 bg-[#0d0e0c]/95 p-4 shadow-2xl shadow-black/70">
                <div className="mb-4 flex items-center justify-between">
                  <div>
                    <p className="font-mono text-base text-ink sm:text-sm">TunnelBar</p>
                    <p className="font-mono text-base text-accent sm:text-sm">Active</p>
                  </div>
                  <StatusDot />
                </div>

                <div className="font-mono text-base text-ink/56 sm:text-sm">LOCAL URL</div>
                <div className="mt-2 min-h-[3.125rem] break-all rounded-md border border-white/10 bg-black/45 px-3 py-3 font-mono text-base text-ink sm:text-sm">
                  <span className="typewriter-url">http://localhost:3000</span>
                </div>

                <div className="relative mt-4 flex items-center gap-2">
                  <button className="start-button-pulse inline-flex items-center gap-2 rounded-md bg-accent px-3 py-2 font-mono text-base text-paper sm:text-sm">
                    <Play className="size-4" aria-hidden="true" />
                    Start
                  </button>
                  <button className="inline-flex items-center gap-2 rounded-md border border-white/10 px-3 py-2 font-mono text-base text-ink/80 sm:text-sm">
                    <Square className="size-4" aria-hidden="true" />
                    Stop
                  </button>
                  <div className="cursor-click-demo" aria-hidden="true">
                    <svg viewBox="0 0 22 22" className="size-5 fill-ink drop-shadow-[0_2px_8px_rgba(0,0,0,0.55)]">
                      <path d="M4.2 2.4 17.8 12l-6.5 1.2-3.5 5.6L4.2 2.4Z" />
                    </svg>
                  </div>
                </div>

                <div className="public-url-reveal mt-5 rounded-md border border-accent/20 bg-accent/8 p-3">
                  <div className="mb-2 flex items-center justify-between">
                    <p className="font-mono text-base text-accent sm:text-sm">PUBLIC URL</p>
                    <Copy className="size-4 text-accent" aria-hidden="true" />
                  </div>
                  <p className="public-url-text break-all font-mono text-base text-ink sm:text-sm">
                    https://demo-tunnel.example
                  </p>
                </div>

              </div>
            </div>
          </div>
        </div>
      </section>

      <section id="flow" className="border-y border-line bg-ink/[0.025]">
        <div className="mx-auto grid max-w-7xl gap-4 px-5 py-16 sm:px-8 lg:grid-cols-3">
          {flowSteps.map((step, index) => (
            <div
              key={step.title}
              className="flow-glow-card min-w-0 overflow-hidden rounded-lg border border-line bg-paper/88 p-5"
              onPointerMove={updateGlowPosition}
            >
              <div className="relative z-10 mb-8 flex items-center justify-between font-mono text-base sm:text-sm">
                <span className="text-accent">0{index + 1}</span>
                <span className="rounded-full border border-line px-2 py-1 text-ink/62">{step.label}</span>
              </div>
              <h2 className="relative z-10 max-w-[18ch] text-balance font-heading text-2xl font-semibold text-ink">
                {step.title}
              </h2>
              <p className="relative z-10 mt-3 text-pretty text-base text-ink/64 sm:text-sm">{step.copy}</p>
              <div className="relative z-20 mt-5 min-h-20 break-all rounded-md border border-line bg-[#070806] p-3 font-mono text-base text-ink/72 sm:text-sm">
                {step.code}
              </div>
            </div>
          ))}
        </div>
      </section>

      <section id="details" className="border-b border-line">
        <div className="mx-auto max-w-7xl px-5 py-20 sm:px-8">
          <div className="max-w-3xl">
            <div className="flex w-fit items-center gap-2 rounded-full border border-line bg-ink/4 px-3 py-1.5 font-mono text-base text-ink/72 sm:text-sm">
              <StatusDot tone="cyan" />
              designed for local dev links
            </div>
            <h2 className="mt-5 max-w-[15ch] text-balance font-heading text-4xl font-semibold text-ink sm:text-5xl">
              No dashboard. No account ceremony.
            </h2>
            <p className="mt-5 max-w-[58ch] text-pretty text-lg text-ink/64 sm:text-base">
              Temporary tunnels are public by design. TunnelBar keeps the rules small, visible, and close to the action.
            </p>
          </div>

          <div className="mt-9 overflow-hidden rounded-lg border border-line bg-[#080907] shadow-2xl shadow-black/30 outline-1 -outline-offset-1 outline-white/10">
            <div className="flex flex-col gap-3 border-b border-line bg-[#171816] px-4 py-3 font-mono text-base text-ink/70 sm:flex-row sm:items-center sm:justify-between sm:text-sm">
              <div className="flex items-center gap-2 text-ink">
                <Terminal className="size-4 text-accent" aria-hidden="true" />
                tunnelbar rules
              </div>
              <div className="text-ink/52">local URL -&gt; temporary public URL</div>
            </div>

            <div className="grid divide-y divide-line sm:grid-cols-2 sm:divide-x sm:divide-y-0 lg:grid-cols-4">
              {featureRows.map(([title, copy], index) => (
                <div key={title} className="min-h-44 p-5">
                  <div className="mb-8 flex items-center justify-between font-mono text-base sm:text-sm">
                    <span className="text-ink/52">0{index + 1}</span>
                    <Check className="size-4 text-accent" aria-hidden="true" />
                  </div>
                  <h3 className="font-mono text-base text-accent sm:text-sm">{title}</h3>
                  <p className="mt-3 text-pretty text-base text-ink/64 sm:text-sm">{copy}</p>
                </div>
              ))}
            </div>
          </div>
        </div>
      </section>

      <section className="mx-auto grid max-w-7xl gap-6 px-5 pb-20 pt-14 sm:px-8 lg:grid-cols-[9fr_15fr] lg:items-center">
        <div className="flex flex-col gap-5">
          <div className="flex w-fit items-center gap-2 rounded-full border border-line bg-ink/4 px-3 py-1.5 font-mono text-base text-ink/72 sm:text-sm">
            <StatusDot />
            clipboard history
          </div>
          <h2 className="max-w-[12ch] text-balance font-heading text-4xl font-semibold text-ink sm:text-5xl">
            Recent links stay in the menu bar.
          </h2>
          <p className="max-w-[50ch] text-pretty text-lg text-ink/64 sm:text-base">
            TunnelBar keeps the last local URL and public tunnel URL together, so you can copy the same routed link again without restarting the flow.
          </p>
        </div>

        <div className="overflow-hidden rounded-lg border border-line bg-[#080907] shadow-2xl shadow-black/40 outline-1 -outline-offset-1 outline-white/10">
          <div className="flex items-center justify-between border-b border-line bg-[#171816] px-4 py-3 font-mono text-base text-ink/70 sm:text-sm">
            <div className="flex items-center gap-2">
              <History className="size-4 text-accent" aria-hidden="true" />
              recent tunnels
            </div>
            <div className="flex items-center gap-2 text-ink/56">
              <Menu className="size-4" aria-hidden="true" />
              TunnelBar
            </div>
          </div>

          <div className="grid gap-3 p-4">
            {recentLinks.map((link, index) => (
              <div
                key={link.public}
                className="grid gap-3 rounded-md border border-line bg-paper/88 p-4 sm:grid-cols-[1fr_auto] sm:items-center"
              >
                <div className="min-w-0">
                  <div className="mb-3 flex items-center gap-2 font-mono text-base text-ink sm:text-sm">
                    <Link2 className="size-4 text-accent" aria-hidden="true" />
                    <span>0{index + 1}</span>
                    <span className="rounded-full border border-line px-2 py-0.5 text-ink/56">
                      {link.state}
                    </span>
                  </div>
                  <div className="grid gap-2 font-mono text-base sm:text-sm">
                    <p className="break-all text-ink/56">
                      <span className="text-accent">local</span> {link.local}
                    </p>
                    <p className="break-all text-ink">
                      <span className="text-accent">public</span> {link.public}
                    </p>
                  </div>
                </div>

                <div className="inline-flex w-fit items-center gap-2 rounded-md border border-line bg-ink/5 px-3 py-2 font-mono text-base text-ink/72 sm:text-sm">
                  <Copy className="size-4" aria-hidden="true" />
                  Copy
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section id="status" className="relative h-[clamp(8.75rem,20vw,17rem)] overflow-hidden border-t border-line">
        <div className="mx-auto flex h-full max-w-7xl items-end px-5 sm:px-8">
          <p className="status-wordmark translate-y-[10px] whitespace-nowrap font-mono font-semibold" aria-label="TunnelBar">
            % tunnelbar
          </p>
        </div>
      </section>

      <footer className="border-t border-line">
        <div className="mx-auto flex max-w-7xl flex-col gap-4 px-5 py-6 font-mono text-base text-ink/52 sm:flex-row sm:items-center sm:justify-between sm:px-8 sm:text-sm">
          <p>TunnelBar by 74LAB</p>
          <div className="flex items-center gap-3">
            <a
              href="https://buymeacoffee.com/tonyroslund"
              target="_blank"
              rel="noreferrer"
              className="group relative grid size-9 place-items-center rounded-md border border-line bg-ink/5 text-ink/72 hover:border-accent/50 hover:text-accent focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-accent"
              aria-label="Support on Buy Me a Coffee"
            >
              <img
                src="/bmc-cup.svg"
                alt=""
                className="h-5 w-auto"
              />
              <img
                src="/bmc-cup-hover.svg"
                alt=""
                className="absolute h-5 w-auto opacity-0 transition-opacity group-hover:opacity-100 group-focus-visible:opacity-100"
              />
            </a>
            <a
              href="https://x.com/tonyroslund"
              target="_blank"
              rel="noreferrer"
              className="grid size-9 place-items-center rounded-md border border-line bg-ink/5 text-ink/72 hover:border-accent/50 hover:text-accent"
              aria-label="Follow Tony Roslund on X"
            >
              <svg viewBox="0 0 24 24" className="size-4 fill-current" aria-hidden="true">
                <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231Zm-1.161 17.52h1.833L7.084 4.126H5.117Z" />
              </svg>
            </a>
          </div>
        </div>
      </footer>
    </main>
  );
}
