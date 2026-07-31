import { vehicles } from "../../data/mock";

export function Vehicules() {
  return (
    <section className="vehicles-page">
      <h1>Mes vehicules</h1>

      <div className="data-table-wrap">
        <table className="data-table">
          <thead>
            <tr>
              <th>Model</th>
              <th>Nom personnalisé</th>
              <th>Catégorie</th>
              <th>Plaque</th>
            </tr>
          </thead>
          <tbody>
            {vehicles.map((vehicle) => (
              <tr key={vehicle.plate}>
                <td>{vehicle.model}</td>
                <td>{vehicle.customName}</td>
                <td>{vehicle.category}</td>
                <td>{vehicle.plate}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );
}
