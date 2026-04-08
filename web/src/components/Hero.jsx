import { useCounter } from '../hooks/useCounter'

function HeroStat({ value, decimals = 0, suffix = '', label }) {
  const { ref, value: animated } = useCounter(value, decimals, 1600)
  const display = decimals > 0
    ? animated.toFixed(decimals)
    : Math.round(animated).toLocaleString('cs-CZ')

  return (
    <div className="hero-stat">
      <span className="hero-stat-num" ref={ref}>{display}{suffix}</span>
      <span className="hero-stat-label">{label}</span>
    </div>
  )
}

export default function Hero() {
  return (
    <section id="hero" className="hero">
      <div className="hero-grid-bg" aria-hidden="true" />
      <div className="container">
        <div className="hero-content">
          <div className="hero-bar" aria-hidden="true" />
          <div>
            <div className="hero-kicker">
              Prostorová analýza&nbsp;·&nbsp;POGEO 2026&nbsp;·&nbsp;PSP ČR 2025
            </div>
            <h1 className="hero-title">
              Analýza<br />
              volebního<br />
              úspěchu<br />
              <span className="gold">Pirátů</span>
            </h1>
            <p className="hero-sub">
              Geographically Weighted Regression na úrovni 6&nbsp;157 českých obcí —
              odkrývá prostorovou nestacionaritu vztahů mezi sociodemografií
              a volební podporou České pirátské strany.
            </p>
            <div className="hero-meta">
              <div className="hero-meta-item">
                <span className="hero-meta-label">Autoři</span>
                <span className="hero-meta-value">Vojtěch Svoboda &amp; Petr Mikeska</span>
              </div>
              <div className="hero-meta-item">
                <span className="hero-meta-label">Kurz</span>
                <span className="hero-meta-value">POGEO</span>
              </div>
              <div className="hero-meta-item">
                <span className="hero-meta-label">Datum</span>
                <span className="hero-meta-value">Duben 2026</span>
              </div>
            </div>
            <div className="hero-ctas">
              <a
                href="#shrnuti"
                className="btn-primary"
                aria-label="Přejít na shrnutí výsledků"
              >
                <svg width="14" height="14" viewBox="0 0 14 14" fill="none" aria-hidden="true">
                  <path d="M7 1v12M1 7l6 6 6-6" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                </svg>
                Výsledky analýzy
              </a>
              <a
                href={`${import.meta.env.BASE_URL}assets/Prezentace_Svobods_mikeska.pptx`}
                className="btn-secondary"
                download
                aria-label="Stáhnout prezentaci ve formátu PPTX"
              >
                <svg width="14" height="14" viewBox="0 0 14 14" fill="none" aria-hidden="true">
                  <path d="M7 1v8M3 6l4 4 4-4M1 12h12" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                </svg>
                Stáhnout prezentaci
              </a>
            </div>

            <div className="hero-stats-grid">
              <HeroStat value={6157} label="Obcí v analýze" />
              <HeroStat value={8.97} decimals={2} suffix="%" label="Národní výsledek" />
              <HeroStat value={0.445} decimals={3} label="GWR R²" />
              <HeroStat value={25.6} decimals={1} suffix=" p.p." label="Zlepšení R²" />
            </div>
          </div>
        </div>
      </div>

      <div className="scroll-cue" aria-hidden="true">
        <span className="scroll-cue-text">Scroll</span>
        <div className="scroll-arrow" />
      </div>
    </section>
  )
}
