export function Skyline({ className = "" }: { className?: string }) {
  return (
    <svg
      className={className}
      viewBox="0 0 1440 280"
      xmlns="http://www.w3.org/2000/svg"
      preserveAspectRatio="xMidYMax meet"
      aria-hidden="true"
    >
      <g fill="#070304">
        <path d="M0 280V188H28V150H52V188H78V165H118V280Z" />
        <path d="M118 280V155H148V118H178V88H208V118H238V155H268V280Z" />
        <path d="M268 280V170H298V130H338V95H368V130H408V170H438V280Z" />
        <path d="M450 280V160H490V115H530V70H565V40H590V70H625V115H665V160H705V280Z" />
        <path d="M720 280V175H760V125H800V85H840V125H880V175H920V280Z" />
        <path d="M935 280V165H975V120H1015V155H1055V130H1095V185H1135V280Z" />
        <path d="M1150 280V175H1190V140H1230V105H1270V140H1310V175H1350V280Z" />
        <path d="M1350 280V195H1385V160H1440V280Z" />
      </g>
      <g fill="#e61e25" opacity="0.18">
        <rect x="40" y="162" width="3" height="8" />
        <rect x="190" y="100" width="3" height="8" />
        <rect x="355" y="108" width="3" height="8" />
        <rect x="575" y="52" width="3" height="8" />
        <rect x="815" y="98" width="3" height="8" />
        <rect x="1030" y="132" width="3" height="8" />
        <rect x="1250" y="118" width="3" height="8" />
      </g>
    </svg>
  );
}
