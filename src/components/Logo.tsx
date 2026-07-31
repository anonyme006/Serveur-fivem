type LogoProps = {
  size?: number;
  framed?: boolean;
  className?: string;
};

export function Logo({ size = 72, framed = false, className = "" }: LogoProps) {
  return (
    <svg
      className={className}
      width={size}
      height={size}
      viewBox="0 0 120 120"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      aria-hidden="true"
    >
      {framed && (
        <rect
          x="8"
          y="8"
          width="104"
          height="104"
          rx="10"
          stroke="currentColor"
          strokeWidth="2"
          opacity="0.85"
        />
      )}
      <polygon
        points="60,14 98,36 98,84 60,106 22,84 22,36"
        fill="#1a0506"
        stroke="#e61e25"
        strokeWidth="4"
      />
      <path
        d="M60 28 L86 44 V76 L60 92 L34 76 V44 Z"
        stroke="#ffffff"
        strokeWidth="2"
        fill="none"
        opacity="0.9"
      />
      <path
        d="M60 28 V92 M34 44 L86 76 M86 44 L34 76"
        stroke="#ffffff"
        strokeWidth="1.2"
        opacity="0.55"
      />
      <circle cx="60" cy="60" r="6" fill="#e61e25" />
    </svg>
  );
}

export function BrandMark({
  size = 42,
  stacked = false,
  className = "",
}: {
  size?: number;
  stacked?: boolean;
  className?: string;
}) {
  return (
    <div className={`brand-mark ${stacked ? "brand-mark--stacked" : ""} ${className}`.trim()}>
      <Logo size={size} />
      <div className="brand-mark__text" aria-label="RE ROLL">
        <span>RE</span>
        <span className="brand-mark__roll">ROLL</span>
      </div>
    </div>
  );
}
