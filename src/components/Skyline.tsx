export function Skyline({ className = "" }: { className?: string }) {
  return (
    <svg
      className={className}
      viewBox="0 0 1440 320"
      xmlns="http://www.w3.org/2000/svg"
      preserveAspectRatio="xMidYMax meet"
      aria-hidden="true"
    >
      <defs>
        <linearGradient id="skyGlow" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#e61e25" stopOpacity="0.35" />
          <stop offset="100%" stopColor="#e61e25" stopOpacity="0" />
        </linearGradient>
      </defs>
      <rect width="1440" height="320" fill="url(#skyGlow)" opacity="0.4" />
      <g fill="#0a0a0a" stroke="#e61e25" strokeWidth="1.2" opacity="0.95">
        <path d="M0 320 V210 H40 V160 H70 V210 H110 V180 H150 V320 Z" />
        <path d="M150 320 V150 H190 V110 H230 V150 H270 V190 H310 V320 Z" />
        <path d="M320 320 V200 H350 V140 H390 V90 H420 V140 H460 V200 H490 V320 Z" />
        <path d="M510 320 V170 H560 V120 H600 V80 H640 V120 H680 V170 H730 V320 Z" />
        <path d="M740 320 V210 H780 V150 H820 V100 H860 V150 H900 V210 H940 V320 Z" />
        <path d="M960 320 V180 H1000 V130 H1040 V180 H1080 V150 H1120 V220 H1160 V320 Z" />
        <path d="M1170 320 V200 H1210 V160 H1250 V120 H1290 V160 H1330 V200 H1370 V320 Z" />
        <path d="M1370 320 V230 H1400 V190 H1440 V320 Z" />
      </g>
      <g fill="#120507" opacity="0.9">
        <rect x="55" y="175" width="6" height="10" />
        <rect x="205" y="125" width="6" height="10" />
        <rect x="400" y="105" width="6" height="10" />
        <rect x="610" y="95" width="6" height="10" />
        <rect x="830" y="115" width="6" height="10" />
        <rect x="1055" y="145" width="6" height="10" />
        <rect x="1265" y="135" width="6" height="10" />
      </g>
    </svg>
  );
}
