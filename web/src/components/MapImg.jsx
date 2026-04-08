import { useState } from 'react'
import Lightbox from './Lightbox'

export default function MapImg({ src, alt, caption, source }) {
  const [open, setOpen] = useState(false)

  return (
    <>
      <div className="map-wrap">
        <img
          src={src} alt={alt} loading="lazy"
          onClick={() => setOpen(true)}
          title="Klikni pro zvětšení"
        />
        <div className="map-caption">
          <span>{caption}</span>
          {source && <span>{source}</span>}
        </div>
      </div>
      {open && <Lightbox src={src} alt={alt} onClose={() => setOpen(false)} />}
    </>
  )
}
