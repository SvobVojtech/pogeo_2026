import { useReveal } from '../hooks/useReveal'
import StatStrip from './StatStrip'
import MapImg from './MapImg'

const STATS = [
  { value:  0.080, decimals: 3, label: "Moran's I (OLS)" },
  { value:  0.001, decimals: 3, label: 'p-hodnota (OLS)' },
  { value: -0.002, decimals: 3, label: "Moran's I (GWR)", color: 'var(--green)' },
  { value:  0.574, decimals: 3, label: 'p-hodnota (GWR)', color: 'var(--green)' },
]

export default function MoransI() {
  const ref = useReveal()

  return (
    <section id="morans-i" ref={ref}>
      <div className="container">
        <div className="section-label">06 — Moran's I diagnostika</div>
        <h2 className="section-title reveal">
          Prostorová <span className="gold">autokorelace</span>
        </h2>
        <p className="section-lead reveal delay-1">
          Moran's I test reziduí OLS modelu: mají sousední obce podobná rezidua?
          Pokud ano, OLS nestačí.
        </p>

        <div className="map-grid-2 reveal delay-2">
          <MapImg
            src="/maps/02_mapa_rezidua_ols.png"
            alt="Rezidua OLS modelu"
            caption="Rezidua OLS — prostorové shluky patrné"
          />
          <MapImg
            src="/figures/08_moran_scatterplot_ols.png"
            alt="Moran scatterplot OLS reziduí"
            caption="Moran scatterplot — OLS rezidua vs. prostorové zpoždění"
          />
        </div>

        <div className="reveal delay-3">
          <StatStrip items={STATS} />
        </div>

        <div className="highlight reveal delay-3">
          <strong>Interpretace:</strong> Moran's I = 0,080 je statisticky průkazné
          (p = 0,001 ***). OLS rezidua vykazují{' '}
          <strong>pozitivní prostorovou autokorelaci</strong> — sousední obce mají
          systematicky podobná rezidua. To svědčí o prostorové{' '}
          <strong>nestacionaritě vztahů</strong> a nutnosti geograficky váženého přístupu.
        </div>

        <div className="big-quote reveal delay-3">
          Relationship between education and<br />
          Pirate support is not the same everywhere.
        </div>
      </div>
    </section>
  )
}
