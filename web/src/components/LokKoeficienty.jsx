import { useReveal } from '../hooks/useReveal'
import MapImg from './MapImg'

const COEFS = [
  {
    name:   'VZDELANI_VYSOKO — VŠ vzdělání',
    ols:    '+0,112',
    min:    -0.206,
    minStr: '−0,206',
    med:    '+0,089',
    max:    +0.426,
    maxStr: '+0,426',
    // Range: min=-0.206 max=+0.426 span=0.632 → zero at 0.206/0.632=32.6%
    zeroAt: 32.6,
  },
  {
    name:   'VZDELANI_STR_BEZ — Vyučení bez maturity',
    ols:    '−0,079',
    min:    -0.374,
    minStr: '−0,374',
    med:    '−0,075',
    max:    +0.167,
    maxStr: '+0,167',
    // span=0.541 → zero at 0.374/0.541=69.1%
    zeroAt: 69.1,
  },
  {
    name:   'PODNIKATELE — Podnikatelé / OSVČ',
    ols:    '+0,071',
    min:    -0.177,
    minStr: '−0,177',
    med:    '+0,045',
    max:    +0.237,
    maxStr: '+0,237',
    // span=0.414 → zero at 0.177/0.414=42.8%
    zeroAt: 42.8,
  },
]

const TABLE_ROWS = [
  ['VŠ vzdělání',          '+0,112', '−0,206', '+0,089', '+0,426', true],
  ['Vyučení bez maturity', '−0,079', '−0,374', '−0,075', '+0,167', true],
  ['Podnikatelé / OSVČ',   '+0,071', '−0,177', '+0,045', '+0,237', true],
]

export default function LokKoeficienty() {
  const ref = useReveal()

  return (
    <section id="lokalni-koeficienty" ref={ref}>
      <div className="container">
        <div className="section-label">08 — Lokální koeficienty</div>
        <h2 className="section-title reveal">
          Prostorová <span className="gold">nestacionarita</span>
        </h2>
        <p className="section-lead reveal delay-1">
          Lokální koeficienty mění znaménko napříč územím — klíčový důkaz nestacionarity.
          Vztah mezi vzděláním a hlasováním pro Piráty není všude stejný.
        </p>

        {/* Range bars */}
        <div className="coef-range reveal delay-2">
          {COEFS.map(({ name, ols, minStr, med, maxStr, zeroAt }) => (
            <div key={name}>
              <div className="coef-row-header">
                <span className="coef-name">{name}</span>
                <span className="coef-ols-badge">OLS globální: {ols}</span>
              </div>
              <div className="range-bar-wrap">
                <div className="range-zero" style={{ left: `${zeroAt}%` }} />
                <div className="range-fill" style={{ left: '3%', right: '3%' }} />
              </div>
              <div className="range-labels">
                <span className="range-label-min">Min: {minStr}</span>
                <span className="range-label-med">Medián: {med}</span>
                <span className="range-label-max">Max: {maxStr}</span>
              </div>
            </div>
          ))}
        </div>

        {/* Table */}
        <div className="table-wrap reveal delay-3">
          <table>
            <thead>
              <tr>
                <th>Prediktor</th>
                <th style={{ textAlign: 'right' }}>OLS globální</th>
                <th style={{ textAlign: 'right' }}>Lok. minimum</th>
                <th style={{ textAlign: 'right' }}>Lok. medián</th>
                <th style={{ textAlign: 'right' }}>Lok. maximum</th>
                <th>Flip znaménka?</th>
              </tr>
            </thead>
            <tbody>
              {TABLE_ROWS.map(([label, ols, min, med, max, flips]) => (
                <tr key={label}>
                  <td>{label}</td>
                  <td className="td-right" style={{ color: ols.startsWith('+') ? 'var(--green)' : 'var(--red)' }}>{ols}</td>
                  <td className="td-right td-neg">{min}</td>
                  <td className="td-right">{med}</td>
                  <td className="td-right td-pos">{max}</td>
                  <td>{flips && <span className="badge">Ano ✓</span>}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Maps */}
        <div className="map-grid-3 reveal delay-3">
          <MapImg src="maps/04_coef_VZDELANI_VYSOKO.png"  alt="Lokální koeficient VŠ vzdělání"      caption="Lok. koef. — VŠ vzdělání"        source="RdBu škála" />
          <MapImg src="maps/05_coef_VZDELANI_STR_BEZ.png" alt="Lokální koeficient vyučení"          caption="Lok. koef. — Vyučení bez mat."   source="RdBu škála" />
          <MapImg src="maps/06_coef_PODNIKATELE.png"      alt="Lokální koeficient podnikatelé"       caption="Lok. koef. — Podnikatelé"         source="RdBu škála" />
        </div>

        <div className="highlight reveal">
          <strong>Klíčové zjištění:</strong> VZDELANI_VYSOKO má v Praze a Brně silný
          pozitivní efekt (+0,426). V průmyslových regionech severních Čech a části
          Moravy se koeficient obrací — vyšší vzdělanost zde{' '}
          <em>nesouvisí</em> s vyšší podporou Pirátů. V těchto oblastech dominují
          jiné faktory volebního rozhodování.
        </div>
      </div>
    </section>
  )
}
