import { useReveal } from '../hooks/useReveal'
import MapImg from './MapImg'

const COEFS = [
  { label: '(Intercept)',            coef: '+8,667', se: '0,433', pval: '***', style: '' },
  { label: 'VŠ vzdělání',            coef: '+0,112', se: '0,010', pval: '***', style: 'td-pos' },
  { label: 'Vyučení bez maturity',   coef: '−0,079', se: '0,008', pval: '***', style: 'td-neg' },
  { label: 'Neprac. důchodci',       coef: '−0,022', se: '0,007', pval: '**',  style: 'td-neg' },
  { label: 'Podnikatelé / OSVČ',     coef: '+0,071', se: '0,008', pval: '***', style: 'td-pos' },
  { label: 'Nezaměstnanost',         coef: '−0,037', se: '0,013', pval: '**',  style: 'td-neg' },
  { label: 'Věřící',                 coef: '−0,020', se: '0,003', pval: '***', style: 'td-neg' },
]

export default function OLSModel() {
  const ref = useReveal()

  return (
    <section id="ols-model" ref={ref}>
      <div className="container">
        <div className="section-label">05 — OLS Model</div>
        <h2 className="section-title reveal">
          Globální <span className="gold">OLS</span> regrese
        </h2>
        <p className="section-lead reveal delay-1">
          Referenční model — každý prediktor má jediný globální koeficient
          platný pro celé území ČR.
        </p>

        <div className="two-col">
          <div>
            <div className="table-wrap reveal delay-1">
              <table>
                <thead>
                  <tr>
                    <th>Prediktor</th>
                    <th style={{ textAlign: 'right' }}>Koeficient</th>
                    <th style={{ textAlign: 'right' }}>Std. chyba</th>
                    <th>p-hodnota</th>
                  </tr>
                </thead>
                <tbody>
                  {COEFS.map(({ label, coef, se, pval, style }) => (
                    <tr key={label}>
                      <td>{label}</td>
                      <td className={`td-right ${style}`}><strong>{coef}</strong></td>
                      <td className="td-right td-dim">{se}</td>
                      <td><span className="sig">{pval}</span></td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            <p className="reveal" style={{ fontSize: '0.76rem', color: 'var(--dim)', marginTop: '0.5rem' }}>
              *** p &lt; 0.001 &nbsp;·&nbsp; ** p &lt; 0.01 &nbsp;·&nbsp; VIF max = 2,71 (bez multikolinearity)
            </p>
          </div>

          <div>
            <div className="card reveal delay-1" style={{ marginBottom: '1rem' }}>
              <div className="card-label">Kvalita modelu</div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginTop: '0.75rem' }}>
                {[
                  { num: '0,188', label: 'R²' },
                  { num: '0,188', label: 'Adj. R²' },
                  { num: '29 130', label: 'AICc', dim: true },
                  { num: '6 157', label: 'n obcí', dim: true },
                ].map(({ num, label, dim }) => (
                  <div key={label}>
                    <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: '2.3rem', color: dim ? 'rgba(255,255,255,0.65)' : 'var(--gold)', lineHeight: 1 }}>{num}</div>
                    <div style={{ fontSize: '0.68rem', color: 'var(--dim)', textTransform: 'uppercase', letterSpacing: '0.09em', marginTop: '0.2rem' }}>{label}</div>
                  </div>
                ))}
              </div>
            </div>

            <div className="highlight reveal delay-2">
              <strong>Problém:</strong> R² = 0,188 znamená, že model vysvětluje
              jen ~19&nbsp;% variability volební podpory. Zbývajících 81&nbsp;% leží
              mimo model — pravděpodobně v{' '}
              <strong>prostorové heterogenitě vztahů</strong>.
            </div>

            <div className="reveal delay-3">
              <MapImg
                src={`${import.meta.env.BASE_URL}figures/12_ols_forest_plot.png`}
                alt="Forest plot OLS koeficientů"
                caption="Standardizované koeficienty OLS modelu"
                source="Vlastní výpočet"
              />
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
