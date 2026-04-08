import { useReveal } from '../hooks/useReveal'

const HISTORY = [
  { rok: 2013, vysledek: '2,66 %', poznamka: 'První parlamentní volby — pod 5% hranicí', highlight: false },
  { rok: 2017, vysledek: '10,79 %', poznamka: 'Samostatná kandidatura — historicky nejlepší výsledek', highlight: true },
  { rok: 2021, vysledek: '≈ 15,6 %', poznamka: 'Koalice Piráti + Starostové (STAN) — podíl nelze přesně oddělit', highlight: false },
  { rok: 2025, vysledek: '8,97 %', poznamka: 'Analyzované volby — samostatná kandidatura', highlight: true },
]

export default function Historie() {
  const ref = useReveal()

  return (
    <section id="historie" ref={ref}>
      <div className="container">
        <div className="section-label">02 — Volební historie</div>
        <h2 className="section-title reveal">
          Vývoj volební <span className="gold">podpory</span>
        </h2>
        <p className="section-lead reveal delay-1">
          Parlamentní volby 2013–2025: od okrajové strany k relevantnímu hráči
          a zpět jako samostatný subjekt.
        </p>

        <div className="table-wrap reveal delay-2">
          <table>
            <thead>
              <tr>
                <th>Volby</th>
                <th>Rok</th>
                <th style={{ textAlign: 'right' }}>Výsledek</th>
                <th>Poznámka</th>
              </tr>
            </thead>
            <tbody>
              {HISTORY.map(({ rok, vysledek, poznamka, highlight }) => (
                <tr key={rok}>
                  <td>PSP ČR</td>
                  <td style={highlight ? { color: 'var(--gold)', fontWeight: 600 } : {}}>
                    {rok}
                  </td>
                  <td className={`td-right${highlight ? ' td-gold' : ''}`}>{vysledek}</td>
                  <td className="td-dim">{poznamka}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        <div className="highlight reveal delay-3">
          <strong>Metodická poznámka:</strong> Analýza pracuje s volbami 2025, kdy Piráti
          kandidují jako samostatná strana. Výsledky 2021 jsou součástí koalice se Starosty
          (STAN) — nelze spolehlivě izolovat pirátský podíl na úrovni obcí.
        </div>
      </div>
    </section>
  )
}
