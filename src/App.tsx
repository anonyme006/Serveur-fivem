import { Navigate, Route, Routes } from "react-router-dom";
import { PanelLayout } from "./components/PanelLayout";
import { Landing } from "./pages/Landing";
import { Login } from "./pages/Login";
import { Accueil } from "./pages/panel/Accueil";
import { Personnage } from "./pages/panel/Personnage";
import { Placeholder } from "./pages/panel/Placeholder";
import { Vehicules } from "./pages/panel/Vehicules";

export default function App() {
  return (
    <Routes>
      <Route path="/" element={<Landing />} />
      <Route path="/login" element={<Login />} />
      <Route path="/panel" element={<PanelLayout />}>
        <Route index element={<Accueil />} />
        <Route path="personnage" element={<Personnage />} />
        <Route path="vehicules" element={<Vehicules />} />
        <Route
          path="images"
          element={
            <Placeholder
              title="Mes images"
              description="Galerie des captures et images liées à votre personnage."
            />
          }
        />
        <Route
          path="mrp"
          element={
            <Placeholder
              title="Demandes MRP"
              description="Suivez et créez vos demandes de mort RP depuis cet espace."
            />
          }
        />
        <Route
          path="medias"
          element={
            <Placeholder
              title="Mes medias"
              description="Retrouvez ici vos médias et fichiers partagés avec le staff."
            />
          }
        />
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
