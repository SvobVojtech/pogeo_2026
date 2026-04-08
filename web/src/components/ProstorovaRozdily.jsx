import { useReveal } from '../hooks/useReveal'
import StatStrip from './StatStrip'
import MapImg from './MapImg'

const STATS = [
  { value: 16.85, decimals: 2, suffix: '%', label: 'Praha' },
  { value: 8.97,  decimals: 2, suffix: '%', label: 'Národní výsledek' },
  { value: 6.78,  decimals: 2, suffix: '%', label: 'Průměr obcí' },
  { value: 24.11, decimals: 2, suffix: '%', label: 'Maximum v obci' },
  { value: 6157,  label: 'Obcí celkem' },
]

export default function ProstorovaRozdily() {
  const ref = useReveal()

  return (
    <section id="prostorove-rozdily" ref={ref}>
      <div className="container">
        <div className="section-label">03 — Prostorové rozdíly</div>
        <h2 className="section-title reveal">
          Kde Piráti <span className="gold">uspěli</span>?
        </h2>
        <p className="section-lead reveal delay-1">
          Silná koncentrace podpory v metropolitních centrech. Průměr obcí (6,78&nbsp;%)
          výrazně zaostává za celostátním výsledkem (8,97&nbsp;%).
        </p>

        <div className="reveal delay-2">
          <StatStrip items={STATS} />
        </div>

        <div className="reveal delay-3">
          <MapImg
            src="/maps/01_mapa_pirati_uspech.png"
            alt="Mapa volebního úspěchu Pirátů v obcích ČR 2025"
            caption="Volební úspěch Pirátů — PSP ČR 2025 | n = 6 157 obcí"
            source="Zdroj: ČSÚ 2025 | Škála: YlOrRd"
          />
        </div>

        <div className="highlight reveal delay-3">
          <strong>Proč průměr obcí (6,78&nbsp;%) &lt; celostátní výsledek (8,97&nbsp;%)?</strong>
          <br />
          Piráti dominují ve velkých městech (Praha, Brno), která mají velkou populaci.
          V nevážném průměru obcí má Praha stejnou váhu jako vesnice s 60 voliči —
          toto je metodicky správný a očekávaný stav, nikoli chyba v datech.
        </div>
      </div>
    </section>
  )
}
