export default function Footer() {
  return (
    <footer className="footer">
      <div className="container">
        <div className="footer-logo">
          <img src={`${import.meta.env.BASE_URL}logo.png`} alt="Piráti logo" />
          <span style={{ fontFamily: 'Space Grotesk, sans-serif', fontSize: '0.9rem', color: 'var(--dim)' }}>
            Analýza volebního úspěchu Pirátů — PSP ČR 2025
          </span>
        </div>

        {/* Authors */}
        <div className="authors-grid" style={{ maxWidth: 680, margin: '0 auto 2.5rem' }}>
          <div className="author-card">
            <div className="author-name">Vojtěch Svoboda</div>
            <div className="author-role">Autor analýzy &nbsp;·&nbsp; POGEO 2026</div>
            <a
              href="https://svobodavojtech.cz/"
              className="author-link"
              target="_blank"
              rel="noopener noreferrer"
              aria-label="Web Vojtěcha Svobody"
            >
              <svg width="13" height="13" viewBox="0 0 13 13" fill="none" aria-hidden="true">
                <path d="M2 2h9v9M11 2 2 11" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"/>
              </svg>
              svobodavojtech.cz
            </a>
          </div>
          <div className="author-card">
            <div className="author-name">Petr Mikeska</div>
            <div className="author-role">Autor analýzy &nbsp;·&nbsp; POGEO 2026</div>
            <a
              href="https://petrmikeska.cz"
              className="author-link"
              target="_blank"
              rel="noopener noreferrer"
              aria-label="Web Petra Mikesky"
            >
              <svg width="13" height="13" viewBox="0 0 13 13" fill="none" aria-hidden="true">
                <path d="M2 2h9v9M11 2 2 11" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"/>
              </svg>
              petrmikeska.cz
            </a>
          </div>
        </div>

        <div className="footer-inner">
          <p>
            Metoda:{' '}
            <span style={{ color: 'var(--gold)' }}>OLS + GWR (GWmodel R 4.5.2)</span>
            <span className="footer-sep">·</span>
            Data:{' '}
            <span style={{ color: 'var(--gold)' }}>ČSÚ 2025, SLDB 2021</span>
            <span className="footer-sep">·</span>
            n ={' '}
            <span style={{ color: 'var(--gold)' }}>6 157 obcí</span>
          </p>
          <p>
            Kurz: <span style={{ color: 'var(--gold)' }}>POGEO</span>
            <span className="footer-sep">·</span>
            Duben 2026
          </p>
          <p style={{ marginTop: '1.5rem', display: 'flex', gap: '1.25rem', justifyContent: 'center', flexWrap: 'wrap' }}>
            <a href="https://www.geoinformatics.upol.cz/" target="_blank" rel="noopener noreferrer" style={{ color: 'var(--dim)', fontSize: '0.8rem', textDecoration: 'none', opacity: 0.6 }}>
              Katedra geoinformatiky UP
            </a>
            <a href="https://www.pirati.cz/" target="_blank" rel="noopener noreferrer" style={{ color: 'var(--dim)', fontSize: '0.8rem', textDecoration: 'none', opacity: 0.6 }}>
              Česká pirátská strana
            </a>
          </p>
          <p style={{ marginTop: '1rem', fontSize: '0.75rem', opacity: 0.4 }}>
            Výsledky analýzy jsou veřejně dostupné pro akademické účely.
          </p>
        </div>
      </div>
    </footer>
  )
}
