# Server Hardening Project

## Inhoudsopgave

1.  [Introductie: Server Hardening](#server-hardening)
2.  [Bouwproces: Stappenplan voor de Gouden Image](#bouwproces-stappenplan-voor-de-gouden-image)
3.  [Packer en vSphere: De Gouden Image](#packer-en-vsphere-de-gouden-image)
4.  [Preseed: De Volledige Installatie](#preseed-de-volledige-installatie)
5.  [Ansible Role: De Hoge Beveiliging](#ansible-role-de-hoge-beveiliging)
6.  [Ansible Role: Gedetailleerde Hardening Componenten](#ansible-role-gedetailleerde-hardening-componenten)
7.  [Overzicht van Mount Opties](#server-hardening-overzicht-van-mount-opties-in-tabelvorm)
8.  [Uitleg van Mount Opties](#uitleg-van-mount-opties)
9.  [Extra Mogelijkheden](#extra-mogelijkheden)

---

### Server Hardening:

Deze Ansible role en Preseed configuratie automatiseren een robuuste server installatie met focus op beveiliging. Het gehele proces is chronologisch opgebouwd, te beginnen met de Packer-template, gevolgd door Preseed, en tot slot de Ansible-role.

---

#### Bouwproces: Stappenplan voor de Gouden Image

Volg de stappen voor een herhaalbare geharde virtuele machine build.

1.  **Voorbereiding:** Installeer Packer op je machine en zorg dat je toegang hebt tot vSphere.
2.  **Omgevingsvariabelen:** Voor de authenticatie met vSphere moet je de volgende omgevingsvariabelen instellen voordat je het `packer build` commando uitvoert.

    ```
    export PKR_VAR_vsphere_user=admin-xxx
    export PKR_VAR_vsphere_password=xxx
    ```
    Deze variabelen zorgen ervoor dat Packer de juiste inloggegevens heeft om verbinding te maken met je vSphere-omgeving en de virtuele machine te bouwen.

3.  **Configuratie:** Kopieer het bestand `vars.auto.pkrvars.hcl.example` naar `vars.auto.pkrvars.hcl`. Vul alle vereiste variabelen in. Zonder dit is het bouwen een oefening in zinloosheid.
4.  **Validatie:** Valideer je template. Open je terminal in de juiste map en typ: `packer validate .`. Als je geen foutmelding krijgt, ga je door.
5.  **Executie:** Tijd om te bouwen. Gebruik het commando: `packer build .`. Packer doet de rest. Dit is het moment dat de magie gebeurt.

Na de build rolt jouw geharde virtuele machine-image uit de oven, klaar om als basis te dienen voor nieuwe servers. Je kan eventueel meekijken op de vmware console.

---

### Packer en vSphere: De Gouden Image

De **Packer-template** is het recept voor de VM-image. Het bouwt en exporteert een herhaalbare, geharde machine. Packer communiceert met vSphere en maakt een nieuwe virtuele machine aan met de opgegeven specificaties. De machine wordt opgestart en geboot naar de Preseed-configuratie. In combinatie met **vSphere** wordt deze "gouden image" als blauwdruk gebruikt voor elke nieuwe virtuele server. Dit garandeert consistentie, elke keer weer.

---

### Preseed: De Volledige Installatie

Na het booten van de VM neemt de Preseed-file de volledige controle over. De Preseed-file is niet alleen voor de partities; het is de automatische installatie zelf. Het regelt alles wat je normaal handmatig zou doen, zoals de partitie-indeling, de installatie van het besturingssysteem, en de installatie van basispakketten.
Zodra de installatie van het besturingssysteem is voltooid, **reboot de VM**. Na de reboot start Packer de Ansible-role.

#### Preseed: een gedetailleerde blik

De Preseed-file is de blauwdruk voor de geautomatiseerde installatie. Hij is opgebouwd uit verschillende secties die de installatiestappen aansturen.

*   **Algemene instellingen**: Dit deel van de file regelt de basiszaken zoals de taal (`en`), land (`NL`) en tijdzone (`Europe/Amsterdam`).
*   **Netwerk en Gebruikers**: De netwerkconfiguratie wordt automatisch gekozen (`auto`). Een belangrijk beveiligingsaspect is dat er geen extra gebruiker wordt aangemaakt. In plaats daarvan wordt de **root-gebruiker** geconfigureerd, met een tijdelijk wachtwoord (`installer`). De toegang wordt later via de **Ansible-role** gehard door wachtwoord-authenticatie uit te schakelen en te vervangen door een SSH-sleutel.
*   **Softwarepakketten**: De Preseed-file definieert de softwarebronnen. Hij zorgt ervoor dat de `contrib` en `non-free` repositories zijn ingeschakeld en selecteert de benodigde pakketten.
*   **Partitieschema**: Dit is de meest kritische sectie. De `partman` commando's zorgen voor de automatische partitie-indeling. Er wordt een **GPT** label aangemaakt en **LVM** (Logical Volume Management) wordt gebruikt voor maximale flexibiliteit. De "expert_recipe" definieert de specifieke partities (`/`, `/var`, `/home` enz.) en de bijbehorende mount opties, die je in de tabel hieronder gedetailleerd kunt bekijken.
*   **Post-installatie commando's**: In dit deel staan commando's die na de installatie worden uitgevoerd via `preseed/late_command`. Deze commando's voeren cruciale hardening uit, zoals:
    *   Het verwijderen van de tijdelijke `/spaceholder` partitie. Deze partitie wordt tijdens de installatie aangemaakt om alle resterende ruimte in de Volume Group te claimen. Aan het einde van de preseed wordt deze LV verwijderd, waardoor de ruimte vrijkomt. Dit biedt de flexibiliteit om later, indien nodig, andere partities zoals `/` of `/var/log` uit te breiden.
    *   Het toevoegen van extra beveiligingsopties aan de bootloader (`grub`).
    *   Het automatisch toevoegen van een **SSH-sleutel** aan de `authorized_keys` van de root-gebruiker. Dit is essentieel voor de opvolgende Ansible-stap.

    **Let op:** Het tijdelijke wachtwoord en de SSH-sleutel in het [preseed.cfg bestand](https://github.com/rroethof/infra/blob/main/http/preseed.cfg) moeten worden aangepast voor jouw omgeving voordat je deze in productie gebruikt.

---

### Ansible Role: De Hoge Beveiliging

De Ansible-role is de laatste en meest cruciale stap. Het is een verzameling van honderden taken die de uiteindelijke hardening uitvoeren. Deze rol is de sluitsteen die de basisinstallatie omtovert in een productiesysteem dat voldoet aan strenge beveiligingsstandaarden.

Op het moment van schrijven gaat een lynis score van 65 standaard naar ongeveer 85.

---

### Ansible Role: Gedetailleerde Hardening Componenten

De `baseline` Ansible-role voert een brede reeks beveiligingstaken uit, onderverdeeld onder andere in de volgende componenten:

*   **Systeem & Packages**: `facts`, `packages`, `packagemgmt`, `services`, `automatic_updates`
*   **Gebruikers & Authenticatie**: `users`, `password`, `pam`, `limits`, `shell`, `shell_user_config`
*   **SSH Daemon**: `sshd` (uitgebreide hardening van de SSH-server)
*   **Logging & Auditing**: `journal`, `auditd`, `postfix`
*   **Beveiligingstools**: `aide` (Advanced Intrusion Detection Environment), `rkhunter` (Rootkit Hunter), `fail2ban`, `debsums`
*   **Kernel & Systeem**: `sysctl`, `kernel`, `mount`, `module_blocklists`, `suid_sgid_blocklist`
*   **Netwerk**: `ipv6` (configuratie en hardening), `ntp`, `arpwatch`
*   **Systeemtaken**: `cron`, `scheduled_tasks`, `motd`, `banners`
*   **Specifieke Services**: `wazuh` (agent installatie), `usbguard`, `prelink`, `compilers`
*   **Policies**: `crypto_policies`, `systemd` (algemene configuratie)

---

### Server Hardening: Overzicht van Mount Opties in Tabelvorm

De volgende tabel biedt een duidelijk overzicht van de aanbevolen mount opties voor elke partitie in een geharde serveromgeving, inclusief de redenen voor de gekozen instellingen.

| Partitie            | Grootte   | Mount Opties                               | Reden                                                                 |
| :------------------ | :-------- | :---------------------------------------- | :------------------------------------------------------------------- |
| **/boot/efi**       | 512 MB    | `nosuid`, `nodev`, `noexec`, `relatime`   | Essentieel voor UEFI-opstart. `noexec` voorkomt het uitvoeren van ongewenste code. `nosuid` en `nodev` helpen bij het voorkomen van privilege-escalatie. |
| **/boot**           | 2 GB      | `nosuid`, `nodev`, `noexec`, `relatime`   | Bevat de kernel en initramfs. `noexec` voorkomt uitvoering van onnodige bestanden na het opstarten. |
| **/** (root)        | 16 GB     | `nosuid`, `nodev`, `relatime`             | Hoofd-bestandssysteem. `nosuid` en `nodev` voorkomen privilege-escalatie. **`noexec` is niet van toepassing** omdat dit het opstarten van het systeem zou hinderen. |
| **/var**            | 8 GB      | `nosuid`, `nodev`, `relatime`             | Voor variabele data. `nosuid` en `nodev` zorgen voor beveiliging. `noexec` wordt vermeden om installatieproblemen te voorkomen. |
| **/var/log**        | 16 GB     | `nosuid`, `nodev`, `noexec`, `relatime`   | Logbestanden, beveiliging is hier belangrijk. `noexec` voorkomt uitvoeren van scripts vanuit logbestanden. |
| **/var/log/audit**  | 16 GB     | `nosuid`, `nodev`, `noexec`, `relatime`   | Auditlogs, gevoelige informatie. Beveiliging zoals `/var/log`. `noexec` voorkomt de uitvoering van ongewenste scripts. |
| **/home**           | 4 GB      | `nosuid`, `nodev`, `relatime`             | Gebruikersmappen. `nosuid` en `nodev` zorgen voor beveiliging. **`noexec` wordt vermeden** voor gebruikersfunctionaliteit. |
| **`swap`**          | 8 GB      | N.v.t.                                    | Gebruikt voor paging. Geen bestanden gemount, puur voor virtueel geheugen. |

### Reservering voor groei:

*   **Totale schijfgrootte**: 102 GB
*   **Toegewezen aan partities**: 71 GB
*   **Vrije ruimte voor groei**: 31 GB

De vrije ruimte is beschikbaar binnen de LVM Volume Group en kan worden gebruikt om bestaande partities zoals `/var` of `/home` uit te breiden.

---

### Uitleg van Mount Opties

*   **`nosuid` (No Set User ID)**: Negeert de "Set User ID" en "Set Group ID" bits op bestanden. Hierdoor kan een programma niet de rechten van een andere gebruiker (bijvoorbeeld root) aan de hand nemen om kwaadaardige acties uit te voeren. Dit voorkomt privilege-escalatie.

*   **`nodev` (No Device)**: Voorkomt dat speciale apparaatbestanden op deze partitie worden geïnterpreteerd. Het is een extra beveiligingslaag die voorkomt dat een aanvaller een apparaatbestand aanmaakt om toegang te krijgen tot de kernel of hardware.

*   **`noexec` (No Execution)**: Verbiedt de uitvoering van uitvoerbare bestanden en scripts op de partitie. Ideaal voor data-partities (`/tmp`, `/var`, `/home`) waar geen uitvoerbare code verwacht wordt. Het is een sterke verdediging tegen malware en scripts.

*   **`relatime` (Relative Access Time)**: Een prestatie-optie. Het update de "access time" (het moment dat een bestand laatst werd gelezen) van een bestand alleen als de vorige a-time ouder is dan de "modify time" (het moment dat het bestand laatst werd gewijzigd). Dit vermindert de I/O-overhead en verbetert de prestaties, zonder dat je belangrijke metadata verliest.

*   **`ro` (Read-Only)**: Monteert de partitie in alleen-lezenmodus, wat schrijfacties voorkomt. Het is de ultieme beveiligingsmaatregel, omdat het onmogelijk wordt om de inhoud te wijzigen.

---

### Extra mogelijkheden: Beveiliging vs. Bruikbaarheid

Deze sectie beschrijft extra beveiligingsopties en de belangrijke afwegingen tussen maximale veiligheid en de dagelijkse bruikbaarheid van het systeem.

*   **Read-Only Partities (`ro`)**
    De `ro` (read-only) mount optie biedt de ultieme bescherming tegen onbedoelde wijzigingen of malware.
    *   **Aanbevolen voor `/boot`**: Het is een goede praktijk om `/boot` en `/boot/efi` na de installatie read-only te maken.
    *   **De afweging**: Het nadeel is dat het systeembeheer complexer wordt. Voor een kernel- of bootloader-update moet de partitie handmatig herschreven worden naar read-write (`rw`), de update uitgevoerd worden, en daarna weer teruggezet worden naar `ro`. Dit proces is lastig te automatiseren en vereist handmatige interventie.

*   **Non-Executable Partities (`noexec`)**
    De `noexec` optie voorkomt dat bestanden op een partitie uitgevoerd kunnen worden. Dit is een sterke verdediging, maar kan niet overal toegepast worden.
    *   **Waarom niet op `/` (root)?**: De rootpartitie bevat alle essentiële systeembestanden en commando's (in `/bin`, `/sbin`). Met `noexec` zou het besturingssysteem weigeren deze uit te voeren, wat leidt tot een onbruikbaar systeem dat niet kan opstarten.
    *   **Waarom niet op `/var`?**: Veel systeemdiensten en de package manager (`apt`) gebruiken de `/var` map om bestanden en scripts uit te voeren tijdens installaties of updates. `noexec` op `/var` zou leiden tot onvoorspelbare fouten en mislukte software-updates.
    *   **Waar wel?**: Deze optie is ideaal voor partities waar nooit uitvoerbare bestanden horen te staan, zoals `/var/log` en `/var/log/audit`.

*   **Flexibiliteit met LVM en GPT**
    Het gebruik van LVM en een GPT-partitietabel (zoals in dit project) biedt een toekomstbestendige en flexibele basis, waardoor het eenvoudiger is om partities later aan te passen.
