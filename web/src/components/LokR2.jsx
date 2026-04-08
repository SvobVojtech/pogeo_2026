import { useReveal } from '../hooks/useReveal'
import StatStrip from './StatStrip'
import MapImg from './MapImg'

const STATS = [
  { value: 0.243, decimals: 3, label: 'Minimum R²' },
  { value: 0.406, decimals: 3, label: 'Medián R²' },
  { value: 0.433, decimals: 3, label: 'Průměr R²', color: 'var(--gold)' },
  { value: 0.838, decimals: 3, label: 'Maximum R²' },
]

export default function LokR2() {
  const ref = useReveal()

  return (
    <section id="lokalni-r2" ref={ref}>
      <div className="container">
        <div className="section-label">09 — Lokální R²</div>
        <h2 className="section-title reveal">
          Kde model <span className="gold">funguje</span>?
        </h2>
        <p className="section-lead reveal delay-1">
          Lokální R² ukazuje, jak dobře GWR vysvětluje volební chování
          v každé konkrétní obci — od 24&nbsp;% po 84&nbsp;%.
        </p>

        <div className="reveal delay-2">
          <StatStrip items={STATS} />
        </div>

        <div className="reveal delay-2">
                    <MapImg
            src={`${import.meta.env.BASE_URL}maps/03_mapa_local_R2.png`}
            alt="Mapa lokálního R²"
            caption="Lokální R² pro GWR model"
            source="Vlastní výpočet"
          />
        </div>

        <div className="highlight reveal delay-3">
          <strong>Interpretace:</strong> GWR model nejlépe vysvětluje volební chování
          v metropolitních oblastech (Praha, Brno, Ostrava) a pohraničních regionech
          — lokální R² dosahuje až 0,838. Slabší vysvětlitelnost (R² kolem 0,243)
          se vyskytuje v rurálních oblastech středních Čech, kde sociodemografické
          prediktory nestačí zachytit specifika lokálního volebního rozhodování.
        </div>
      </div>
    </section>
  )
}
