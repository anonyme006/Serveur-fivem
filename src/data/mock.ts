export const character = {
  firstName: "Teddy",
  lastName: "Vega",
  playerName: "TeddyRP",
  phone: "555-0182",
  registration: "3",
  playtime: "42h 18m",
  gender: "male" as const,
  online: false,
  job: "Aucun",
  grade: "Aucun grade",
};

export const licenses = [
  { id: "car", label: "Voiture", status: "Invalide" },
  { id: "truck", label: "Camion", status: "Invalide" },
  { id: "moto", label: "Moto", status: "Invalide" },
  { id: "heli", label: "Hélicoptère", status: "Invalide" },
  { id: "plane", label: "Avion", status: "Invalide" },
  { id: "boat", label: "Bateau", status: "Invalide" },
  { id: "weapon", label: "Port d'arme", status: "Invalide" },
  { id: "hunt", label: "Chasse", status: "Invalide" },
  { id: "fish", label: "Pêche", status: "Invalide" },
  { id: "firstaid", label: "1er secours", status: "Invalide" },
];

export const vehicles = [
  {
    model: "panto",
    customName: "—",
    category: "Compacts",
    plate: "30LAZ831",
  },
];

export const serverStatus = {
  online: true,
  players: 10,
  whitelistAccepted: true,
};
