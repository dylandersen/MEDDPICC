# MEDDPICC Insights for Salesforce

AI-powered deal qualification analysis on the Account page, fueled by Clari Copilot data.

![Salesforce API v65.0](https://img.shields.io/badge/Salesforce%20API-v65.0-blue)
![License: MIT](https://img.shields.io/badge/License-MIT-green)

<!-- Screenshot placeholder — replace with your own -->
<!-- ![MEDDPICC Insights](docs/screenshot.png) -->

## What It Does

MEDDPICC Insights surfaces deal qualification intelligence directly on the Salesforce Account page. It reads MEDDPICC assessment data that Clari Copilot writes into a custom Salesforce object, then lets reps and managers click a single button to get an AI-generated executive summary of deal health — all without leaving the account record.

- **Clari → Salesforce sync** — assessments written by Clari Copilot are consumed automatically
- **AI deal analysis** — strengths, risk areas, next steps, competitive positioning, and a bottom-line forecast in one click
- **Multi-model support** — choose from 6 LLMs (Gemini, GPT, Claude) via the Salesforce Models API
- **MEDDPICC dimension grid** — visual score bars for all 8 dimensions with expandable notes
- **Score ring** — circular indicator showing overall qualification score (0–10), color-coded green/orange/red
- **Recommended next action** — AI surfaces the best contact to reach out to, with "Draft Email" and "Ask Agentforce" shortcuts
- **Multi-opportunity support** — when an account has multiple assessments, a picker aggregates at-a-glance stats across all deals

## Architecture

```
Clari Copilot
      |
      | (native Salesforce integration)
      v
MEDDPICC_Assessment__c   ←──  Account (master-detail)
      |                        Opportunity (lookup)
      |
      v
meddpiccInsights LWC  (on Account Record Page)
      |
      |  getMeddpiccData()  ─── SOQL
      |  analyzeMeddpicc()
      v
MeddpiccAnalysisController.cls
      |
      |  buildPrompt()  →  aiplatform.ModelsAPI  →  LLM
      |                           |
      |          (Gemini / GPT / Claude / Bedrock)
      v
AI analysis HTML  +  [RECOMMENDED_CONTACT] extraction
      |
      v
Rendered in LWC via <lightning-formatted-rich-text>
```

**Data layer:** `MEDDPICC_Assessment__c` is a master-detail child of Account. It holds 8 text fields (one per MEDDPICC dimension), 8 numeric score fields (0–10 each), a formula-calculated `Overall_Score__c`, and sync metadata (`Synced_From_Clari__c`, `Last_Clari_Sync__c`).

**Analysis layer:** `MeddpiccAnalysisController.cls` fetches up to 10 assessments for the account, builds a structured prompt that tells the LLM to act as a B2B sales strategist, calls the selected model via the Salesforce Agentforce AI platform, then parses a hidden `[RECOMMENDED_CONTACT:Name]` marker from the response before returning it to the component.

**UI layer:** `meddpiccInsights` LWC lives on the Account Record Page. It renders the dimension grid, score ring, opportunity picker (multi-deal accounts), the Analyze button, and the AI result panel — all with animated loading states.

## Component Map

```
force-app/main/default/
├── lwc/
│   └── meddpiccInsights/         ← Account Record Page component
│       ├── meddpiccInsights.html  ← Template (loading, empty, error, main, analysis states)
│       ├── meddpiccInsights.js    ← Controller: data load, dimension grid, AI trigger
│       ├── meddpiccInsights.css   ← Full component styles (score ring, bars, model picker)
│       └── meddpiccInsights.js-meta.xml  ← Exposed on Account Record Pages only
├── classes/
│   ├── MeddpiccAnalysisController.cls      ← Apex: SOQL, prompt builder, Models API caller
│   └── MeddpiccAnalysisControllerTest.cls  ← Unit test coverage
├── objects/
│   └── MEDDPICC_Assessment__c/
│       ├── MEDDPICC_Assessment__c.object-meta.xml  ← Custom object definition
│       └── fields/                                  ← 21 custom fields
├── permissionsets/
│   └── MEDDPICC_Assessment_Access.permissionset-meta.xml
├── staticresources/
│   └── clari.png                  ← Clari logo (badge in component)
└── scripts/apex/
    ├── create_pdc_meddpicc_assessment.apex       ← Demo: active deal
    ├── create_pdc_meddpicc_closed_lost.apex      ← Demo: closed-lost deal
    └── create_pdc_meddpicc_rfp_stuck.apex        ← Demo: stalled RFP deal
```

## Supported AI Models

| Model | Provider | Model API ID |
|-------|----------|-------------|
| Gemini Flash 3.0 | Google (Vertex AI) | `sfdc_ai__DefaultVertexAIGemini30Flash` |
| Gemini Pro 3.0 | Google (Vertex AI) | `sfdc_ai__DefaultVertexAIGeminiPro30` |
| GPT-5 | OpenAI | `sfdc_ai__DefaultGPT5` |
| GPT-5.2 | OpenAI | `sfdc_ai__DefaultGPT52` |
| Claude Sonnet 4.5 | Anthropic (Bedrock) | `sfdc_ai__DefaultBedrockAnthropicClaude45Sonnet` |
| Claude Opus 4.5 | Anthropic (Bedrock) | `sfdc_ai__DefaultBedrockAnthropicClaude45Opus` |

## Prerequisites

- Salesforce org with **Agentforce / Models API** enabled (see [Models API docs](https://developer.salesforce.com/docs/Agentforce/genai/guide/models-api.html))
- API version **65.0+** (Winter '26)
- Models API access configured for at least one of the models above
- **Clari Copilot** with its native Salesforce integration active and configured to write MEDDPICC data into `MEDDPICC_Assessment__c` (see [Clari Setup](#clari-setup) below)
- The `aiplatform` Apex namespace available in your org

## Quick Start

```bash
# 1. Clone the repo
git clone <your-repo-url>
cd MEDDPICC

# 2. Authenticate to your target org
sf org login web -a myorg

# 3. Deploy all metadata
sf project deploy start -o myorg
```

After deployment, continue with the steps below.

---

## Post-Deploy Setup

### 1. Assign the Permission Set

Grant users access to the custom object and component:

1. Go to **Setup → Permission Sets**
2. Open **MEDDPICC Assessment Access**
3. Click **Manage Assignments → Add Assignments**
4. Select the users or profiles that need access and save

This permission set grants full CRUD on `MEDDPICC_Assessment__c`, read/edit on Account, and read-only on Opportunity and Contact.

---

### 2. Upload Missing Static Resources

The LWC references several static resources for model logos that are **not included in this repo** (they are hosted in the source org). You must upload these manually before the component will render correctly:

1. Go to **Setup → Static Resources → New**
2. Upload each of the following files with the exact names shown:

| Name | File | Cache Control |
|------|------|---------------|
| `AgentforceRGBIcon` | Agentforce icon PNG | Public |
| `Gemini` | Gemini logo PNG | Public |
| `OpenAI` | OpenAI logo SVG | Public |
| `Claude` | Claude logo SVG | Public |

> The `clari` static resource (Clari logo) **is** included in the deployment and requires no manual upload.

---

### 3. Add the Component to the Account Record Page

The `meddpiccInsights` LWC is configured to appear only on **Account Record Pages**. You must add it via Lightning App Builder:

1. Open any Account record in Salesforce
2. Click the **gear icon (⚙)** in the top-right → **Edit Page**
3. In the Lightning App Builder, find **meddpiccInsights** in the component panel (left sidebar, under "Custom" components)
4. Drag it onto the page layout — recommended placement:
   - A **right-side column** (1/3 width) works well for the score ring and dimension grid
   - Or a **full-width section** below the highlights panel for the analysis output
5. Click **Save**
6. Click **Activate** if the page hasn't been activated yet:
   - Choose **Assign as Org Default** for all users, or
   - Use **App, Record Type, and Profile** assignments for more granular control
7. Click **Save** on the activation dialog

> **Tip:** If you want the component visible immediately when a rep opens an account, place it in a tab labeled "MEDDPICC" or "Deal Health" on the record page. This keeps the standard account layout clean while making the analysis one tab click away.

---

### 4. Clari Integration

There are two ways to get Clari MEDDPICC data into Salesforce: the **Clari Align native connector** (no code, recommended for most orgs) and the **Clari Copilot REST API** (for custom pipelines or scheduled sync jobs). Both paths ultimately write into `MEDDPICC_Assessment__c`.

---

#### Path A — Clari Align Native Salesforce Connector (Recommended)

Clari Align has a built-in Salesforce integration that can map workspace fields directly onto Salesforce Opportunity fields and push activity as Salesforce Tasks. For full setup details, see the [Clari Align + Salesforce integration guide](https://community.clari.com/align-73/integrating-align-with-salesforce-852).

**Field mapping setup:**

1. In Clari, go to **Align → Organization Settings → Field Mapping**
2. Click **+ Add Mapping** for each MEDDPICC dimension
3. Map the Align workspace field to the corresponding `MEDDPICC_Assessment__c` field:

| Align Workspace Field | Salesforce Field API Name | Type |
|---|---|---|
| Metrics (notes) | `Metrics__c` | LongTextArea |
| Metrics (score) | `Score_Metrics__c` | Number (0–10) |
| Economic Buyer (notes) | `Economic_Buyer__c` | LongTextArea |
| Economic Buyer (score) | `Score_Economic_Buyer__c` | Number (0–10) |
| Decision Criteria (notes) | `Decision_Criteria__c` | LongTextArea |
| Decision Criteria (score) | `Score_Decision_Criteria__c` | Number (0–10) |
| Decision Process (notes) | `Decision_Process__c` | LongTextArea |
| Decision Process (score) | `Score_Decision_Process__c` | Number (0–10) |
| Paper Process (notes) | `Paper_Process__c` | LongTextArea |
| Paper Process (score) | `Score_Paper_Process__c` | Number (0–10) |
| Identify Pain (notes) | `Identify_Pain__c` | LongTextArea |
| Identify Pain (score) | `Score_Identify_Pain__c` | Number (0–10) |
| Champion (notes) | `Champion__c` | LongTextArea |
| Champion (score) | `Score_Champion__c` | Number (0–10) |
| Competition (notes) | `Competition__c` | LongTextArea |
| Competition (score) | `Score_Competition__c` | Number (0–10) |

4. Click **Publish Changes**. Field syncs take up to 15 minutes; use **Run Full Sync Now** to force an immediate push.
5. Set the **parent Account** relationship: Clari should populate `Account__c` from the linked Opportunity's account (`AccountId`).
6. Enable **CRM Activity** if you want Clari Align workspace activity (buyer/seller engagement events) to also appear as completed Tasks on the Salesforce Opportunity.

> **Tip:** Configure the `MAP_Status__c` picklist field on Opportunity (values: `ON_TRACK`, `LATE`, `ARCHIVED`) to surface Align plan status directly in Salesforce and the Clari Opportunity Grid. See the [Align community guide](https://community.clari.com/align-73/integrating-align-with-salesforce-852) for exact setup steps.

---

#### Path B — Clari Copilot REST API (Custom / Scheduled Sync)

If you need more control — polling on a schedule, pulling call intelligence alongside MEDDPICC scores, or building a custom middleware — use the [Clari Copilot REST API](https://api-doc.copilot.clari.com/).

**Authentication**

Every request requires two headers:

```http
X-Api-Key: <your-api-key>
X-Api-Password: <your-api-password>
```

Obtain both from your Clari admin (**Settings → API**). Rate limits: **10 requests/second**, **100,000 requests/week** (week resets Sunday 00:00 UTC).

**Key endpoints for this integration**

| Endpoint | Method | Purpose |
|---|---|---|
| `/calls` | GET | List calls with linked deal/account CRM IDs |
| `/call-details` | GET | Full transcript, AI summary, competitor sentiments |
| `/get-deal` | GET | Opportunity data by Salesforce `crm_id` |
| `/update-deal` | PUT | Write custom fields back to Clari from Salesforce |

**Linking Clari deals to Salesforce records**

Clari uses `crm_id` as its foreign key to Salesforce. A Clari deal's `crm_id` is the Salesforce **Opportunity ID** (`006...`). The `account_crm_id` maps to the Salesforce **Account ID** (`001...`). Use these to join records when writing into `MEDDPICC_Assessment__c`.

**Pulling deal data**

```bash
# Fetch a Clari deal by its Salesforce Opportunity ID
curl -X GET "https://rest-api.copilot.clari.com/get-deal?id=006Hu00000EXAMPLE" \
  -H "X-Api-Key: YOUR_KEY" \
  -H "X-Api-Password: YOUR_PASSWORD"
```

The response includes `custom_fields` — a key-value array where you can store MEDDPICC notes and scores if your Clari instance is configured to capture them there.

**Pulling call intelligence to populate Competition and Champion**

The `/call-details` endpoint returns `competitor_sentiments` and `summary.key_action_items` — data that maps naturally into the Competition and Champion MEDDPICC dimensions:

```bash
curl -X GET "https://rest-api.copilot.clari.com/call-details?id=CALL_ID" \
  -H "X-Api-Key: YOUR_KEY" \
  -H "X-Api-Password: YOUR_PASSWORD"
```

Response fields of interest:

```json
{
  "competitor_sentiments": [
    { "competitor_name": "...", "sentiment": "...", "reasoning": "..." }
  ],
  "summary": {
    "full_summary": "...",
    "key_action_items": [
      { "action_item": "...", "speaker_name": "..." }
    ]
  }
}
```

**Listing calls for an account**

Use the `filterTimeGt`/`filterTimeLt` query parameters combined with `crm_info.account_id` matching to pull all calls for a given account over a time window:

```bash
curl -X GET "https://rest-api.copilot.clari.com/calls?filterTimeGt=2026-01-01T00:00:00Z&includePagination=false" \
  -H "X-Api-Key: YOUR_KEY" \
  -H "X-Api-Password: YOUR_PASSWORD"
```

Each call in the response includes `crm_info.account_id` and `crm_info.deal_id` for joining back to Salesforce.

**Writing to `MEDDPICC_Assessment__c` from the API**

Once you have Clari deal and call data, write it to Salesforce using any standard mechanism — Salesforce REST API, a Scheduled Apex job, MuleSoft, or a serverless function. Set `Synced_From_Clari__c = true` and `Last_Clari_Sync__c = DateTime.now()` on every upsert so the LWC badge renders correctly.

Example upsert pattern using the Salesforce REST API:

```http
PATCH /services/data/v65.0/sobjects/MEDDPICC_Assessment__c/Opportunity__c/<OPP_ID>
Content-Type: application/json

{
  "Account__c": "001Hu000...",
  "Opportunity__c": "006Hu000...",
  "Metrics__c": "...",
  "Score_Metrics__c": 8,
  "Competition__c": "...",
  "Score_Competition__c": 5,
  "Synced_From_Clari__c": true,
  "Last_Clari_Sync__c": "2026-04-02T12:00:00Z"
}
```

> Use `Opportunity__c` as the external ID field on the PATCH to upsert (one assessment per opportunity). This requires the field to be marked as an external ID in Salesforce — update the field metadata accordingly if building a custom sync.

---

### 5. Load Demo Data (Optional)

Three anonymous Apex scripts are included to create realistic test assessments:

```bash
# Active deal — healthy scores, competitive situation
sf apex run --file scripts/apex/create_pdc_meddpicc_assessment.apex -o myorg

# Closed-lost deal — low scores across the board
sf apex run --file scripts/apex/create_pdc_meddpicc_closed_lost.apex -o myorg

# Stalled RFP — high pain/fit but stuck in paper process
sf apex run --file scripts/apex/create_pdc_meddpicc_rfp_stuck.apex -o myorg
```

> **Important:** Each script contains a hardcoded Account ID (`001Hu00003ccrTbIAI`). Update this value to a valid Account ID in your target org before running.

---

## Configuration

| Setting | Default | Location |
|---------|---------|----------|
| Default AI model | Gemini Flash 3.0 | Model picker in component UI |
| Max assessments fetched per account | 10 | `getMeddpiccData()` SOQL limit in `MeddpiccAnalysisController.cls` |
| Apex sharing mode | `without sharing` | Class declaration in `MeddpiccAnalysisController.cls` |
| Component target | Account Record Pages only | `targets` in `meddpiccInsights.js-meta.xml` |

---

## Key Features

### MEDDPICC Dimension Grid
All 8 dimensions are displayed as labeled progress bars, color-coded by score (green ≥ 7, orange ≥ 4, red < 4). Click any dimension row to expand the full qualification notes captured by Clari.

### Score Ring
A circular SVG indicator shows the calculated `Overall_Score__c` (average of all 8 dimension scores). The ring stroke color matches the score tier: green for qualified deals, orange for moderate risk, red for at-risk.

### Multi-Opportunity Picker
When an account has multiple assessments (multiple active or historical deals), a dropdown lets the user switch between them. An aggregate bar shows counts of strong, moderate, and at-risk deals across the account.

### AI Analysis
Clicking **✨ Analyze** sends the full assessment data to the selected LLM via the Salesforce Models API. The prompt instructs the model to return a structured HTML analysis with five sections: Strengths, Risk Areas, Next Steps, Competitive Positioning, and Bottom Line.

### Recommended Contact
The AI embeds a hidden `[RECOMMENDED_CONTACT:Name]` marker in its response. The Apex controller strips this from the displayed output and surfaces the name as a suggested outreach target in the post-analysis action bar.

### Action Shortcuts
After analysis, two action buttons appear: **Draft Email** (pre-addressed to the recommended contact) and **Ask Agentforce** (launches Agentforce for deeper conversation). Both are currently stubbed with toast messages and ready for your org's navigation wiring.

---

## Custom Object Reference

`MEDDPICC_Assessment__c` — the core data model.

| Field | API Name | Type |
|-------|----------|------|
| Account | `Account__c` | Master-Detail(Account) |
| Opportunity | `Opportunity__c` | Lookup(Opportunity) |
| Assessment Date | `Assessment_Date__c` | Date |
| Synced From Clari | `Synced_From_Clari__c` | Checkbox |
| Last Clari Sync | `Last_Clari_Sync__c` | DateTime |
| Metrics Notes | `Metrics__c` | LongTextArea |
| Metrics Score | `Score_Metrics__c` | Number (0–10) |
| Economic Buyer Notes | `Economic_Buyer__c` | LongTextArea |
| Economic Buyer Score | `Score_Economic_Buyer__c` | Number (0–10) |
| Decision Criteria Notes | `Decision_Criteria__c` | LongTextArea |
| Decision Criteria Score | `Score_Decision_Criteria__c` | Number (0–10) |
| Decision Process Notes | `Decision_Process__c` | LongTextArea |
| Decision Process Score | `Score_Decision_Process__c` | Number (0–10) |
| Paper Process Notes | `Paper_Process__c` | LongTextArea |
| Paper Process Score | `Score_Paper_Process__c` | Number (0–10) |
| Identify Pain Notes | `Identify_Pain__c` | LongTextArea |
| Identify Pain Score | `Score_Identify_Pain__c` | Number (0–10) |
| Champion Notes | `Champion__c` | LongTextArea |
| Champion Score | `Score_Champion__c` | Number (0–10) |
| Competition Notes | `Competition__c` | LongTextArea |
| Competition Score | `Score_Competition__c` | Number (0–10) |
| Overall Score | `Overall_Score__c` | Formula (Number, 1 decimal) — average of all 8 scores |

---

## Project Structure

```
MEDDPICC/
├── force-app/main/default/
│   ├── classes/
│   │   ├── MeddpiccAnalysisController.cls
│   │   ├── MeddpiccAnalysisController.cls-meta.xml
│   │   ├── MeddpiccAnalysisControllerTest.cls
│   │   └── MeddpiccAnalysisControllerTest.cls-meta.xml
│   ├── lwc/
│   │   └── meddpiccInsights/
│   │       ├── meddpiccInsights.html
│   │       ├── meddpiccInsights.js
│   │       ├── meddpiccInsights.css
│   │       └── meddpiccInsights.js-meta.xml
│   ├── objects/
│   │   └── MEDDPICC_Assessment__c/
│   │       ├── MEDDPICC_Assessment__c.object-meta.xml
│   │       └── fields/  (21 fields)
│   ├── permissionsets/
│   │   └── MEDDPICC_Assessment_Access.permissionset-meta.xml
│   └── staticresources/
│       ├── clari.png
│       └── clari.resource-meta.xml
├── scripts/apex/
│   ├── create_pdc_meddpicc_assessment.apex
│   ├── create_pdc_meddpicc_closed_lost.apex
│   └── create_pdc_meddpicc_rfp_stuck.apex
└── sfdx-project.json
```

---

## License

MIT © 2026 Dylan Andersen — see [LICENSE](LICENSE) for details.
