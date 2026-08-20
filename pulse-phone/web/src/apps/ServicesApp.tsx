import { useEffect, useMemo, useRef, useState, type ReactNode } from 'react';
import { fetchNui, isEnvBrowser } from '@/nui/fetchNui';
import { useNuiEvent } from '@/hooks/useNuiEvent';
import { usePhoneStore } from '@/stores/phoneStore';
import type {
  CompanyChatMessage,
  CompanyManagement,
  CompanyPublic,
  CompanyThread,
  ServicesMe,
} from '@/types/phone';

type TabId = 'companies' | 'messages' | 'actions';

const MOCK_COMPANIES: CompanyPublic[] = [
  {
    id: 'police',
    label: 'Police',
    description: 'Forces de l’ordre',
    location: 'Mission Row',
    number: '911',
    category: 'public',
    status: 'open',
    employeesOnline: 4,
    icon: 'POL',
    iconColor: '#1D4ED8',
    canCall: true,
    position: { x: 428.2, y: -981.0, z: 30.7 },
  },
  {
    id: 'ambulance',
    label: 'EMS',
    description: 'Urgences médicales',
    location: 'Pillbox Hill',
    number: '912',
    category: 'public',
    status: 'busy',
    employeesOnline: 1,
    icon: 'EMS',
    iconColor: '#DC2626',
    canCall: true,
    position: { x: 298.6, y: -584.5, z: 43.3 },
  },
  {
    id: 'mechanic',
    label: 'LS Customs',
    description: 'Réparation véhicules',
    location: 'La Mesa',
    number: '5551001',
    category: 'service',
    status: 'open',
    employeesOnline: 3,
    icon: 'MEC',
    iconColor: '#EA580C',
    canCall: true,
    position: { x: 732.0, y: -1088.7, z: 22.2 },
  },
  {
    id: 'taxi',
    label: 'Taxi',
    description: 'Transport',
    location: 'Downtown',
    number: '5551002',
    category: 'service',
    status: 'closed',
    employeesOnline: 0,
    icon: 'TAX',
    iconColor: '#CA8A04',
    canCall: true,
    position: { x: 895.3, y: -179.3, z: 74.7 },
  },
];

const MOCK_ME: ServicesMe = {
  isEmployee: true,
  isBoss: true,
  onDuty: false,
  companyId: 'mechanic',
  label: 'LS Customs',
  grade: 3,
  gradeLabel: 'Patron',
};

const MOCK_MGMT: CompanyManagement = {
  ok: true,
  companyId: 'mechanic',
  label: 'LS Customs',
  isBoss: true,
  onDuty: false,
  grade: 3,
  gradeLabel: 'Patron',
  balance: 128450,
  status: 'open',
  pendingRequests: 2,
  employees: [
    { name: 'John Doe', grade: 3, gradeLabel: 'Patron', onDuty: true, online: true },
    { name: 'Kevin M.', grade: 1, gradeLabel: 'Mécano', onDuty: true, online: true },
    { name: 'Sara L.', grade: 0, gradeLabel: 'Stagiaire', onDuty: false, online: false },
  ],
};

function formatMoney(n: number): string {
  return new Intl.NumberFormat('fr-FR', {
    style: 'currency',
    currency: 'USD',
    maximumFractionDigits: 0,
  }).format(n);
}

export function ServicesApp(): ReactNode {
  const pushNotification = usePhoneStore((s) => s.pushNotification);
  const [tab, setTab] = useState<TabId>('companies');
  const [companies, setCompanies] = useState<CompanyPublic[]>([]);
  const [me, setMe] = useState<ServicesMe>({ isEmployee: false });
  const [threads, setThreads] = useState<CompanyThread[]>([]);
  const [chat, setChat] = useState<{
    companyId: string;
    label: string;
    icon: string;
    iconColor: string;
    citizenid: string;
    asEmployee: boolean;
    messages: CompanyChatMessage[];
  } | null>(null);
  const [draft, setDraft] = useState('');
  const [mgmt, setMgmt] = useState<CompanyManagement | null>(null);
  const chatEndRef = useRef<HTMLDivElement>(null);

  const loadBootstrap = async () => {
    const data = await fetchNui<{ companies: CompanyPublic[]; me: ServicesMe }>(
      'services:bootstrap',
      {},
      { companies: MOCK_COMPANIES, me: MOCK_ME },
    );
    setCompanies(data?.companies ?? []);
    setMe(data?.me ?? { isEmployee: false });
  };

  const loadThreads = async () => {
    const list = await fetchNui<CompanyThread[]>(
      'services:getThreads',
      {},
      isEnvBrowser()
        ? [
            {
              companyId: 'ambulance',
              label: 'EMS',
              icon: 'EMS',
              iconColor: '#DC2626',
              lastMessage: 'Besoin d’une ambulance au nord.',
              unread: 1,
              citizenid: 'DEV001',
              asEmployee: false,
            },
          ]
        : [],
    );
    setThreads(list ?? []);
  };

  const loadManagement = async () => {
    const data = await fetchNui<CompanyManagement>('services:getManagement', {}, MOCK_MGMT);
    setMgmt(data);
    if (data?.onDuty !== undefined) {
      setMe((prev) => ({ ...prev, onDuty: data.onDuty, isBoss: data.isBoss, isEmployee: true }));
    }
  };

  useEffect(() => {
    void loadBootstrap();
  }, []);

  useEffect(() => {
    if (tab === 'messages') void loadThreads();
    if (tab === 'actions') void loadManagement();
  }, [tab]);

  useEffect(() => {
    chatEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [chat?.messages.length]);

  useNuiEvent<{ companyId: string; body: string; senderName?: string }>('services:companyMessage', (payload) => {
    if (!payload) return;
    pushNotification({
      type: 'company_message',
      title: payload.senderName || 'Services',
      body: payload.body,
    });
    if (chat && chat.companyId === payload.companyId) {
      void openChat(payload.companyId, chat.citizenid, chat.asEmployee);
    } else {
      void loadThreads();
    }
  });

  const unreadTotal = useMemo(
    () => threads.reduce((sum, t) => sum + (t.unread || 0), 0),
    [threads],
  );

  const openChat = async (companyId: string, citizenid?: string, asEmployee = false) => {
    const result = await fetchNui<{
      ok: boolean;
      companyId: string;
      label: string;
      icon: string;
      iconColor: string;
      citizenid: string;
      asEmployee: boolean;
      messages: CompanyChatMessage[];
    }>(
      'services:getChat',
      { companyId, citizenid },
      {
        ok: true,
        companyId,
        label: companies.find((c) => c.id === companyId)?.label || 'Entreprise',
        icon: companies.find((c) => c.id === companyId)?.icon || 'CO',
        iconColor: companies.find((c) => c.id === companyId)?.iconColor || '#0D9488',
        citizenid: citizenid || 'DEV001',
        asEmployee,
        messages: [
          {
            id: 1,
            sender_type: 'player',
            sender_name: 'Kevin',
            body: 'Bonjour, j’ai besoin d’aide.',
            created_at: '2026-08-20 14:00:00',
          },
          {
            id: 2,
            sender_type: 'company',
            sender_name: 'EMS',
            body: 'Nous arrivons, restez en ligne.',
            created_at: '2026-08-20 14:01:00',
          },
        ],
      },
    );
    if (result?.ok) {
      setChat({
        companyId: result.companyId,
        label: result.label,
        icon: result.icon,
        iconColor: result.iconColor,
        citizenid: result.citizenid,
        asEmployee: result.asEmployee,
        messages: result.messages || [],
      });
      setTab('messages');
      setDraft('');
    }
  };

  const sendMessage = async () => {
    if (!chat || !draft.trim()) return;
    const body = draft.trim();
    setDraft('');
    const res = await fetchNui<{ ok: boolean; message?: CompanyChatMessage }>(
      'services:sendMessage',
      {
        companyId: chat.companyId,
        citizenid: chat.asEmployee ? chat.citizenid : undefined,
        body,
      },
      {
        ok: true,
        message: {
          id: Date.now(),
          sender_type: chat.asEmployee ? 'company' : 'player',
          sender_name: chat.asEmployee ? chat.label : 'Moi',
          body,
          created_at: new Date().toISOString(),
        },
      },
    );
    if (res?.ok && res.message) {
      setChat((prev) =>
        prev
          ? {
              ...prev,
              messages: [...prev.messages, res.message!],
            }
          : prev,
      );
    }
  };

  const toggleDuty = async () => {
    const res = await fetchNui<{ ok: boolean; onDuty?: boolean }>(
      'services:toggleDuty',
      {},
      { ok: true, onDuty: !me.onDuty },
    );
    if (res?.ok) {
      setMe((prev) => ({ ...prev, onDuty: res.onDuty }));
      pushNotification({
        type: 'service',
        title: me.label || 'Service',
        body: res.onDuty ? 'Service pris' : 'Service terminé',
      });
      void loadManagement();
    }
  };

  if (chat) {
    return (
      <div className="svc-root svc-chat">
        <div className="svc-chat-head">
          <button type="button" className="svc-icon-btn" onClick={() => setChat(null)} aria-label="Retour">
            ‹
          </button>
          <div className="svc-avatar" style={{ background: chat.iconColor }}>
            {chat.icon}
          </div>
          <div className="svc-chat-title">
            <strong>{chat.label}</strong>
            <span>{chat.asEmployee ? 'Conversation client' : 'Messagerie entreprise'}</span>
          </div>
        </div>
        <div className="svc-chat-body">
          {chat.messages.map((m) => {
            const mine =
              (chat.asEmployee && m.sender_type === 'company') ||
              (!chat.asEmployee && m.sender_type === 'player');
            return (
              <div key={m.id} className={`svc-bubble ${mine ? 'mine' : 'theirs'}`}>
                <p>{m.body}</p>
              </div>
            );
          })}
          <div ref={chatEndRef} />
        </div>
        <div className="svc-chat-input">
          <input
            value={draft}
            onChange={(e) => setDraft(e.target.value)}
            placeholder="Message…"
            onKeyDown={(e) => {
              if (e.key === 'Enter') void sendMessage();
            }}
          />
          <button type="button" className="svc-send" onClick={() => void sendMessage()} disabled={!draft.trim()}>
            ➤
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="svc-root">
      <div className="svc-page">
        {tab === 'companies' && (
          <CompaniesTab
            companies={companies}
            onGps={(c) => {
              if (c.position) void fetchNui('services:setWaypoint', c.position);
            }}
            onCall={(c) => void fetchNui('calls:start', { number: c.number, companyId: c.id })}
            onMessage={(c) => void openChat(c.id)}
          />
        )}
        {tab === 'messages' && (
          <MessagesTab
            threads={threads}
            onOpen={(t) => void openChat(t.companyId, t.citizenid, t.asEmployee)}
          />
        )}
        {tab === 'actions' && (
          <ActionsTab me={me} mgmt={mgmt} onToggleDuty={() => void toggleDuty()} onRefresh={() => void loadManagement()} />
        )}
      </div>
      <nav className="svc-tabs">
        <TabBtn active={tab === 'companies'} label="Entreprises" onClick={() => setTab('companies')} glyph="▣" />
        <TabBtn
          active={tab === 'messages'}
          label="Messages"
          onClick={() => setTab('messages')}
          glyph="✎"
          badge={unreadTotal}
        />
        <TabBtn active={tab === 'actions'} label="Actions" onClick={() => setTab('actions')} glyph="⚙" />
      </nav>
    </div>
  );
}

function TabBtn({
  active,
  label,
  onClick,
  glyph,
  badge,
}: {
  active: boolean;
  label: string;
  onClick: () => void;
  glyph: string;
  badge?: number;
}) {
  return (
    <button type="button" className={`svc-tab ${active ? 'active' : ''}`} onClick={onClick}>
      <span className="svc-tab-glyph">
        {glyph}
        {!!badge && badge > 0 && <i>{badge > 9 ? '9+' : badge}</i>}
      </span>
      <span>{label}</span>
    </button>
  );
}

function CompaniesTab({
  companies,
  onGps,
  onCall,
  onMessage,
}: {
  companies: CompanyPublic[];
  onGps: (c: CompanyPublic) => void;
  onCall: (c: CompanyPublic) => void;
  onMessage: (c: CompanyPublic) => void;
}) {
  return (
    <div className="svc-panel">
      <h3 className="svc-heading">Entreprises</h3>
      <p className="svc-sub">Contacter un service de la ville</p>
      <div className="svc-list">
        {companies.map((c) => (
          <div key={c.id} className="svc-row">
            <div className="svc-avatar" style={{ background: c.iconColor || '#0d9488' }}>
              {c.icon || c.label.slice(0, 2).toUpperCase()}
            </div>
            <div className="svc-row-main">
              <strong>{c.label}</strong>
              <span>
                {c.location || c.category}
                {c.employeesOnline > 0 ? ` · ${c.employeesOnline} en service` : ''}
              </span>
            </div>
            <div className="svc-row-actions">
              <button
                type="button"
                className="svc-act gps"
                title="GPS"
                onClick={() => onGps(c)}
                disabled={!c.position}
              >
                ⊕
              </button>
              {c.canCall !== false && (
                <button type="button" className="svc-act call" title="Appeler" onClick={() => onCall(c)}>
                  ☎
                </button>
              )}
              <button type="button" className="svc-act msg" title="Message" onClick={() => onMessage(c)}>
                ✎
              </button>
            </div>
          </div>
        ))}
        {!companies.length && <p className="placeholder">Aucune entreprise.</p>}
      </div>
    </div>
  );
}

function MessagesTab({
  threads,
  onOpen,
}: {
  threads: CompanyThread[];
  onOpen: (t: CompanyThread) => void;
}) {
  return (
    <div className="svc-panel">
      <h3 className="svc-heading">Messages</h3>
      <p className="svc-sub">Conversations avec les entreprises</p>
      <div className="svc-list">
        {threads.map((t, idx) => (
          <button
            key={`${t.companyId}-${t.citizenid}-${idx}`}
            type="button"
            className="svc-row svc-row-btn"
            onClick={() => onOpen(t)}
          >
            <div className="svc-avatar" style={{ background: t.iconColor }}>
              {t.icon}
            </div>
            <div className="svc-row-main">
              <strong>
                {t.label}
                {t.unread > 0 && <em className="svc-unread">{t.unread}</em>}
              </strong>
              <span>{t.lastMessage}</span>
            </div>
          </button>
        ))}
        {!threads.length && <p className="placeholder">Aucun message pour le moment.</p>}
      </div>
    </div>
  );
}

function ActionsTab({
  me,
  mgmt,
  onToggleDuty,
  onRefresh,
}: {
  me: ServicesMe;
  mgmt: CompanyManagement | null;
  onToggleDuty: () => void;
  onRefresh: () => void;
}) {
  if (!me.isEmployee) {
    return (
      <div className="svc-panel">
        <h3 className="svc-heading">Actions</h3>
        <p className="placeholder" style={{ marginTop: 16 }}>
          Vous n’êtes rattaché à aucune entreprise. Les actions (prise de service, gestion) apparaissent ici pour les
          employés.
        </p>
      </div>
    );
  }

  return (
    <div className="svc-panel">
      <h3 className="svc-heading">{mgmt?.label || me.label || 'Entreprise'}</h3>
      <p className="svc-sub">
        {me.gradeLabel || `Grade ${me.grade}`}
        {me.isBoss ? ' · Direction' : ''}
      </p>

      <button type="button" className={`svc-duty ${me.onDuty ? 'on' : 'off'}`} onClick={onToggleDuty}>
        <span className="svc-duty-dot" />
        {me.onDuty ? 'Quitter le service' : 'Prendre son service'}
      </button>

      {mgmt?.isBoss && typeof mgmt.balance === 'number' && (
        <div className="svc-balance">
          <span>Solde entreprise</span>
          <strong>{formatMoney(mgmt.balance)}</strong>
        </div>
      )}

      {mgmt?.isBoss && (
        <div className="svc-status-row">
          {(['open', 'busy', 'closed'] as const).map((s) => (
            <button
              key={s}
              type="button"
              className={`svc-status-chip ${mgmt.status === s ? 'active' : ''}`}
              onClick={() =>
                void fetchNui('services:setStatus', { companyId: mgmt.companyId, status: s }).then(onRefresh)
              }
            >
              {s === 'open' ? 'Ouvert' : s === 'busy' ? 'Occupé' : 'Fermé'}
            </button>
          ))}
        </div>
      )}

      <div className="svc-section-head">
        <h4>Employés</h4>
        <button type="button" className="svc-link" onClick={onRefresh}>
          Actualiser
        </button>
      </div>
      <div className="svc-list">
        {(mgmt?.employees || []).map((e, i) => (
          <div key={`${e.name}-${i}`} className="svc-emp">
            <div>
              <strong>{e.name}</strong>
              <span>
                {e.gradeLabel} (G{e.grade})
              </span>
            </div>
            <div className={`svc-emp-state ${e.onDuty ? 'duty' : ''} ${e.online === false ? 'off' : ''}`}>
              {e.onDuty ? 'En service' : e.online === false ? 'Hors ligne' : 'Hors service'}
            </div>
          </div>
        ))}
        {!mgmt?.employees?.length && <p className="placeholder">Aucun employé chargé.</p>}
      </div>

      {typeof mgmt?.pendingRequests === 'number' && mgmt.pendingRequests > 0 && (
        <div className="svc-alert">{mgmt.pendingRequests} demande(s) en attente</div>
      )}
    </div>
  );
}
