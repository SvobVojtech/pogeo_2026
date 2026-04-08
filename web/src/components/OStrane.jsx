import { useReveal } from '../hooks/useReveal'

export default function OStrane() {
  const ref = useReveal()

  return (
    <section id="o-strane" ref={ref}>
      <div className="container">
        <div className="section-label">01 — O straně</div>
        <h2 className="section-title reveal">
          Česká <span className="gold">pirátská</span> strana
        </h2>
        <p className="section-lead reveal delay-1">
          Strana digitální éry — transparentnost, participace a otevřená správa věcí veřejných.
        </p>

        <div className="two-col">
          <div>
            <div className="gold-line reveal" />
            <p className="reveal delay-1">
              Česká pirátská strana byla{' '}
              <strong>registrována jako právnická osoba v roce 2012</strong>,
              navazujíc na mezinárodní pirátské hnutí vzniklé v roce 2009.
              Hlásí se k ideálům digitální svobody, radikální transparentnosti
              a přímé demokracie.
            </p>
            <p className="reveal delay-2" style={{ marginTop: '1rem' }}>
              Cílová voličská základna je tvořena zejména{' '}
              <strong>mladými, vysokoškolsky vzdělanými voliči v metropolitních oblastech</strong>{' '}
              — Praha, Brno a větší univerzitní centra. Tento vzorec je empiricky
              potvrzen i naší prostorovou analýzou.
            </p>
            <ul className="check-list">
              <li className="reveal delay-2">Digitální bezpečnost a ochrana soukromí</li>
              <li className="reveal delay-3">Transparentnost veřejné správy a protikorupce</li>
              <li className="reveal delay-3">Regulace technologií a otevřená data</li>
              <li className="reveal delay-4">Kritika centralismu a zákaz lobování</li>
              <li className="reveal delay-4">Občanská participace na rozhodování</li>
            </ul>
          </div>

          <div className="reveal delay-2">
            <div
              className="card"
              style={{ textAlign: 'center', padding: '2.5rem 2rem' }}
            >
              {/* SVG Skull — Pirate motif */}
              <svg
                viewBox="0 0 280 220"
                width="100%"
                style={{ maxWidth: 260, margin: '0 auto', display: 'block' }}
                aria-hidden="true"
              >
                <ellipse cx="140" cy="95" rx="52" ry="56" fill="none" stroke="#F2C700" strokeWidth="2" />
                <circle cx="120" cy="88" r="11" fill="#0a0a0a" stroke="#F2C700" strokeWidth="1.5" />
                <circle cx="160" cy="88" r="11" fill="#0a0a0a" stroke="#F2C700" strokeWidth="1.5" />
                <circle cx="120" cy="88" r="5" fill="#F2C700" />
                <circle cx="160" cy="88" r="5" fill="#F2C700" />
                <path d="M 122 112 Q 140 125 158 112" fill="none" stroke="#F2C700" strokeWidth="2" strokeLinecap="round" />
                <line x1="130" y1="117" x2="130" y2="128" stroke="#F2C700" strokeWidth="1.5" />
                <line x1="140" y1="119" x2="140" y2="130" stroke="#F2C700" strokeWidth="1.5" />
                <line x1="150" y1="117" x2="150" y2="128" stroke="#F2C700" strokeWidth="1.5" />
                <line x1="60" y1="170" x2="220" y2="195" stroke="#F2C700" strokeWidth="2.5" strokeLinecap="round" opacity="0.55" />
                <line x1="220" y1="170" x2="60" y2="195" stroke="#F2C700" strokeWidth="2.5" strokeLinecap="round" opacity="0.55" />
                <text x="140" y="40" textAnchor="middle" fontFamily="Bebas Neue, sans-serif" fontSize="20" fill="#F2C700" letterSpacing="4">ČESKÁ PIRÁTSKÁ</text>
                <text x="140" y="215" textAnchor="middle" fontFamily="Space Grotesk, sans-serif" fontSize="10" fill="rgba(255,255,255,0.38)" letterSpacing="2">REGISTROVÁNO 2012</text>
              </svg>
              <div style={{ marginTop: '1.5rem', display: 'flex', gap: '0.5rem', justifyContent: 'center', flexWrap: 'wrap' }}>
                <span className="badge">Pirátské hnutí</span>
                <span className="badge">od 2012</span>
                <span className="badge">Mezinárodní</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
