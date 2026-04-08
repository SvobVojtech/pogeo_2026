import { useReveal } from '../hooks/useReveal'
import MapImg from './MapImg'

export default function GWRModel() {
  const ref = useReveal()

  return (
    <section id="gwr-model" ref={ref}>
      <div className="container">
        <div className="section-label">07 — GWR Model</div>
        <h2 className="section-title reveal">
          Geographically Weighted <span className="gold">Regression</span>
        </h2>
        <p className="section-lead reveal delay-1">
          Každá obec dostane vlastní regresní model — 6&nbsp;157 lokálních modelů
          místo jednoho globálního.
        </p>

        <div className="formula reveal delay-1">
          <strong>GWR specifikace:</strong>
          {' '}Kernel: <strong>Exponential (adaptive)</strong>
          &nbsp;·&nbsp; Bandwidth: <strong>23 sousedů</strong>
          &nbsp;·&nbsp; Optimalizace: <strong>AICc minimalizace</strong>
          <br />
          Efektivní parametry: <strong>1&nbsp;272,8</strong> (z 6&nbsp;157 pozorování = 0,37&nbsp;% dat)
        </div>

        <div className="compare-grid reveal delay-2">
          {/* OLS */}
          <div className="compare-col">
            <div className="compare-col-label">OLS — Globální model</div>
            {[
              ['R²',                    '0,188'],
              ['Adjusted R²',           '0,188'],
              ['AICc',                  '29 130'],
              ["Moran's I reziduí",     <span style={{ color: 'var(--red)' }}>0,080 ***</span>],
              ['Koeficienty',           '7 globálních'],
              ['Prostorová heterogenita', <span style={{ color: 'var(--red)' }}>Nevyřešena ✗</span>],
            ].map(([key, val]) => (
              <div className="compare-row" key={key}>
                <span className="compare-key">{key}</span>
                <span className="compare-val">{val}</span>
              </div>
            ))}
          </div>

          {/* GWR */}
          <div className="compare-col winner">
            <div className="compare-col-label">GWR — Lokální modely ✓</div>
            {[
              ['R²',                    <><span className="td-gold">0,445</span> <span style={{ fontSize: '0.73rem', color: 'var(--green)' }}>(+25,6 p.p.)</span></>],
              ['Adjusted R²',           <><span className="td-gold">0,300</span> <span style={{ fontSize: '0.73rem', color: 'var(--green)' }}>(+11,2 p.p.)</span></>],
              ['AICc',                  <><span className="td-gold">28 601</span> <span style={{ fontSize: '0.73rem', color: 'var(--green)' }}>(−529)</span></>],
              ["Moran's I reziduí",     <span style={{ color: 'var(--green)' }}>−0,002 (ns) ✓</span>],
              ['Koeficienty',           '6 157 lokálních'],
              ['Prostorová heterogenita', <span style={{ color: 'var(--green)' }}>Eliminována ✓</span>],
            ].map(([key, val]) => (
              <div className="compare-row" key={key}>
                <span className="compare-key">{key}</span>
                <span className="compare-val">{val}</span>
              </div>
            ))}
          </div>
        </div>

        <div className="map-grid-2 reveal delay-3">
          <MapImg
            src="/figures/10_ols_vs_gwr_srovnani.png"
            alt="Srovnání OLS a GWR metrik"
            caption="Vizuální srovnání OLS vs. GWR — čtyři klíčové metriky"
          />
          <MapImg
            src="/figures/11_moran_ols_vs_gwr.png"
            alt="Moran's I OLS vs GWR"
            caption="Eliminace prostorové autokorelace: Moran's I OLS → GWR"
          />
        </div>
      </div>
    </section>
  )
}
