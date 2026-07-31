type PlaceholderProps = {
  title: string;
  description: string;
};

export function Placeholder({ title, description }: PlaceholderProps) {
  return (
    <section className="placeholder-page">
      <h1>{title}</h1>
      <p>{description}</p>
    </section>
  );
}
