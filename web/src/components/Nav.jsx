import { useActiveSection } from '../hooks/useActiveSection'

const NAV_ITEMS = [
  { href: '#o-strane',            label: 'O straně' },
  { href: '#historie',            label: 'Historie' },
  { href: '#prostorove-rozdily',  label: 'Prostorové rozdíly' },
  { href: '#data-metodika',       label: 'Data' },
  { href: '#ols-model',           label: 'OLS' },
  { href: '#morans-i',            label: "Moran's I" },
  { href: '#gwr-model',           label: 'GWR' },
  { href: '#lokalni-koeficienty', label: 'Lok. koef.' },
  { href: '#lokalni-r2',          label: 'Lok. R²' },
  { href: '#shrnuti',             label: 'Shrnutí' },
]

const SECTION_IDS = NAV_ITEMS.map((i) => i.href.slice(1))

export default function Nav() {
  const activeId = useActiveSection(SECTION_IDS)

  return (
    <nav className="nav">
      <div className="nav-inner">
        <a href="#uvod" className="nav-logo">
          <div className="nav-logo-img-wrap">
            <img src={`${import.meta.env.BASE_URL}logo.png`} alt="Piráti logo" className="nav-logo-img" />
          </div>
        </a>
        <ul className="nav-links">
          {NAV_ITEMS.map(({ href, label }) => (
            <li key={href}>
              <a
                href={href}
                className={activeId === href.slice(1) ? 'active' : ''}
              >
                {label}
              </a>
            </li>
          ))}
          <li>
            <a href="https://petrmikeska.cz/pogeo/map/" target="_blank" rel="noopener noreferrer">
              Mapa
            </a>
          </li>
        </ul>
      </div>
    </nav>
  )
}
