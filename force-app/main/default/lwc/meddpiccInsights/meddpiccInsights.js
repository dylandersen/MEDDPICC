import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getMeddpiccData from '@salesforce/apex/MeddpiccAnalysisController.getMeddpiccData';
import analyzeMeddpicc from '@salesforce/apex/MeddpiccAnalysisController.analyzeMeddpicc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import AGENTFORCE_ICON from '@salesforce/resourceUrl/AgentforceRGBIcon';
import GEMINI_LOGO from '@salesforce/resourceUrl/Gemini';
import OPENAI_LOGO from '@salesforce/resourceUrl/OpenAI';
import CLAUDE_LOGO from '@salesforce/resourceUrl/Claude';
import CLARI_LOGO from '@salesforce/resourceUrl/clari';

const MODELS = [
  { id: 'sfdc_ai__DefaultVertexAIGemini30Flash',          label: 'Gemini Flash 3.0', logoKey: 'gemini', premium: false },
  { id: 'sfdc_ai__DefaultVertexAIGeminiPro30',            label: 'Gemini Pro 3.0',   logoKey: 'gemini', premium: false },
  { id: 'sfdc_ai__DefaultGPT5',                           label: 'GPT-5',            logoKey: 'openai', premium: false },
  { id: 'sfdc_ai__DefaultGPT52',                          label: 'GPT-5.2',          logoKey: 'openai', premium: false },
  { id: 'sfdc_ai__DefaultBedrockAnthropicClaude45Sonnet', label: 'Sonnet 4.5',       logoKey: 'claude', premium: false },
  { id: 'sfdc_ai__DefaultBedrockAnthropicClaude45Opus',   label: 'Opus 4.5',         logoKey: 'claude', premium: true  }
];

const LOGO_MAP = { gemini: GEMINI_LOGO, openai: OPENAI_LOGO, claude: CLAUDE_LOGO };
const DEFAULT_MODEL = MODELS[0].id;

const DIMENSION_META = [
  { key: 'scoreMetrics',          label: 'Metrics',           icon: 'utility:chart',   noteKey: 'metrics' },
  { key: 'scoreEconomicBuyer',    label: 'Economic Buyer',    icon: 'utility:money',   noteKey: 'economicBuyer' },
  { key: 'scoreDecisionCriteria', label: 'Decision Criteria', icon: 'utility:rules',   noteKey: 'decisionCriteria' },
  { key: 'scoreDecisionProcess',  label: 'Decision Process',  icon: 'utility:flow',    noteKey: 'decisionProcess' },
  { key: 'scorePaperProcess',     label: 'Paper Process',     icon: 'utility:page',    noteKey: 'paperProcess' },
  { key: 'scoreIdentifyPain',     label: 'Identify Pain',     icon: 'utility:warning', noteKey: 'identifyPain' },
  { key: 'scoreChampion',         label: 'Champion',          icon: 'utility:user',    noteKey: 'champion' },
  { key: 'scoreCompetition',      label: 'Competition',       icon: 'utility:strategy',noteKey: 'competition' }
];

export default class MeddpiccInsights extends NavigationMixin(LightningElement) {
  @api recordId;

  @track allAssessments = [];
  @track assessment = null;
  @track dimensions = [];
  @track aiAnalysis = '';
  @track errorMessage = '';
  @track isLoadingData = true;
  @track isAnalyzing = false;
  @track currentLoadingMessage = '';
  @track selectedModelId = DEFAULT_MODEL;
  @track isModelPickerOpen = false;
  @track accountName = '';
  @track opportunityName = '';
  @track showAnalysis = false;
  @track _expandedKey = null;
  @track recommendedContactName = '';

  agentforceIcon = AGENTFORCE_ICON;
  clariLogo = CLARI_LOGO;

  @track currentDataLoadingMessage = 'Connecting to Clari...';
  @track isTextFading = false;
  dataLoadingMessages = [
    'Connecting to Clari...',
    'Fetching MEDDPICC assessments...',
    'Loading opportunity data...'
  ];
  dataLoadingInterval = null;
  dataLoadingIndex = 0;

  loadingMessages = [
    'Pulling MEDDPICC data from Clari...',
    'Analyzing deal qualification...',
    'Evaluating strengths and risks...',
    'Building strategic insights...'
  ];
  loadingMessageInterval = null;
  loadingMessageIndex = 0;
  static FADE_DURATION = 250;

  connectedCallback() {
    this.loadData();
  }

  disconnectedCallback() {
    this.stopLoadingMessages();
    this.stopDataLoadingMessages();
  }

  _fadeSwap(nextText, setter) {
    this.isTextFading = true;
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    setTimeout(() => {
      setter(nextText);
      this.isTextFading = false;
    }, MeddpiccInsights.FADE_DURATION);
  }

  startLoadingMessages() {
    this.loadingMessageIndex = 0;
    this.currentLoadingMessage = this.loadingMessages[0];
    this.isTextFading = false;
    this.loadingMessageInterval = setInterval(() => {
      this.loadingMessageIndex = (this.loadingMessageIndex + 1) % this.loadingMessages.length;
      this._fadeSwap(this.loadingMessages[this.loadingMessageIndex], (t) => {
        this.currentLoadingMessage = t;
      });
    }, 2500);
  }

  stopLoadingMessages() {
    if (this.loadingMessageInterval) {
      clearInterval(this.loadingMessageInterval);
      this.loadingMessageInterval = null;
    }
    this.currentLoadingMessage = '';
    this.isTextFading = false;
  }

  startDataLoadingMessages() {
    this.dataLoadingIndex = 0;
    this.currentDataLoadingMessage = this.dataLoadingMessages[0];
    this.isTextFading = false;
    this.dataLoadingInterval = setInterval(() => {
      this.dataLoadingIndex = (this.dataLoadingIndex + 1) % this.dataLoadingMessages.length;
      this._fadeSwap(this.dataLoadingMessages[this.dataLoadingIndex], (t) => {
        this.currentDataLoadingMessage = t;
      });
    }, 2000);
  }

  stopDataLoadingMessages() {
    if (this.dataLoadingInterval) {
      clearInterval(this.dataLoadingInterval);
      this.dataLoadingInterval = null;
    }
    this.isTextFading = false;
  }

  loadData() {
    this.isLoadingData = true;
    this.errorMessage = '';
    this.startDataLoadingMessages();

    getMeddpiccData({ accountId: this.recordId })
      .then((result) => {
        if (result.error) {
          this.errorMessage = result.error;
          return;
        }
        this.accountName = result.accountName || '';
        if (result.assessments && result.assessments.length > 0) {
          this.allAssessments = result.assessments;
          this.selectAssessment(result.assessments[0]);
        }
      })
      .catch((error) => {
        this.errorMessage = error.body?.message || error.message || 'Failed to load MEDDPICC data.';
      })
      .finally(() => {
        this.isLoadingData = false;
        this.stopDataLoadingMessages();
      });
  }

  selectAssessment(assess) {
    this.assessment = assess;
    this.opportunityName = assess.opportunityName || '';
    this.aiAnalysis = '';
    this.showAnalysis = false;
    this.recommendedContactName = '';
    this._expandedKey = null;
    this.buildDimensions();
  }

  buildDimensions() {
    if (!this.assessment) return;
    this.dimensions = DIMENSION_META.map((dim) => {
      const score = this.assessment[dim.key] || 0;
      const note = this.assessment[dim.noteKey] || '';
      const widthPct = (score / 10) * 100;
      return {
        key: dim.key,
        label: dim.label,
        icon: dim.icon,
        noteKey: dim.noteKey,
        score,
        note,
        hasNote: Boolean(note),
        barStyle: 'width:' + widthPct + '%',
        barClass: 'score-bar-fill ' + this.getScoreColorClass(score),
        scoreClass: 'dim-score ' + this.getScoreColorClass(score)
      };
    });
  }

  getScoreColorClass(score) {
    if (score >= 7) return 'score-high';
    if (score >= 4) return 'score-medium';
    return 'score-low';
  }

  // ─── Opportunity Picker ────────────────────────────────

  get hasMultipleAssessments() {
    return this.allAssessments.length > 1;
  }

  get opportunityPickerOptions() {
    return this.allAssessments.map((a) => {
      const score = Math.round(a.overallScore || 0);
      const scoreLabel = score >= 7 ? 'Strong' : score >= 4 ? 'Moderate' : 'At Risk';
      const name = a.opportunityName || 'No Opportunity';
      const label = name + '  —  ' + score + '/10 ' + scoreLabel;
      return { label, value: a.id };
    });
  }

  get assessmentCountLabel() {
    return this.allAssessments.length + ' assessed';
  }

  get avgScore() {
    if (!this.allAssessments.length) return '0';
    const sum = this.allAssessments.reduce((acc, a) => acc + (a.overallScore || 0), 0);
    return (sum / this.allAssessments.length).toFixed(1);
  }

  get strongCount() {
    return this.allAssessments.filter((a) => Math.round(a.overallScore || 0) >= 7).length;
  }

  get moderateCount() {
    return this.allAssessments.filter((a) => {
      const s = Math.round(a.overallScore || 0);
      return s >= 4 && s < 7;
    }).length;
  }

  get atRiskCount() {
    return this.allAssessments.filter((a) => Math.round(a.overallScore || 0) < 4).length;
  }

  get selectedAssessmentId() {
    return this.assessment?.id || '';
  }

  handleOpportunityChange(event) {
    const newId = event.detail.value;
    if (newId === this.assessment?.id) return;
    const found = this.allAssessments.find((a) => a.id === newId);
    if (found) {
      this.selectAssessment(found);
    }
  }

  // ─── Analyze ───────────────────────────────────────────

  handleAnalyze() {
    if (!this.recordId || !this.assessment) return;
    this.isAnalyzing = true;
    this.aiAnalysis = '';
    this.errorMessage = '';
    this.showAnalysis = false;
    this.recommendedContactName = '';
    this.startLoadingMessages();

    analyzeMeddpicc({
      accountId: this.recordId,
      modelName: this.selectedModelId,
      assessmentId: this.assessment.id
    })
      .then((result) => {
        if (result.error) {
          this.errorMessage = result.error;
        } else {
          this.aiAnalysis = result.aiAnalysis || '';
          this.recommendedContactName = result.recommendedContactName || '';
          this.showAnalysis = true;
        }
      })
      .catch((error) => {
        this.errorMessage = error.body?.message || error.message || 'AI analysis failed.';
        this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: this.errorMessage, variant: 'error' }));
      })
      .finally(() => {
        this.isAnalyzing = false;
        this.stopLoadingMessages();
      });
  }

  handleDimensionToggle(event) {
    const key = event.currentTarget.dataset.key;
    this._expandedKey = this._expandedKey === key ? null : key;
  }

  // ─── Action Buttons ────────────────────────────────────

  handleDraftEmail() {
    const name = this.recommendedContactName || 'Key Contact';
    this.dispatchEvent(new ShowToastEvent({
      title: 'Drafting Email',
      message: 'Email Draft Generation in Progress for ' + name + '...',
      variant: 'info',
      mode: 'dismissible'
    }));
  }

  handleAskAgentforce() {
    this.dispatchEvent(new ShowToastEvent({
      title: 'Agentforce',
      message: 'Asking Agentforce for Next Steps...',
      variant: 'success',
      mode: 'dismissible'
    }));
  }

  // ─── Record Navigation ──────────────────────────────────

  handleNavigateToOpportunity(event) {
    event.stopPropagation();
    const oppId = this.assessment?.opportunityId;
    if (!oppId) return;
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: { recordId: oppId, objectApiName: 'Opportunity', actionName: 'view' }
    });
  }

  handleNavigateToAssessment(event) {
    event.stopPropagation();
    const assessId = this.assessment?.id;
    if (!assessId) return;
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: { recordId: assessId, objectApiName: 'MEDDPICC_Assessment__c', actionName: 'view' }
    });
  }

  get hasOpportunityId() { return Boolean(this.assessment?.opportunityId); }
  get assessmentRecordName() { return this.assessment?.name || 'MEDDPICC Assessment'; }
  get hasAssessmentId() { return Boolean(this.assessment?.id); }

  // ─── Expanded dimension detail ─────────────────────────

  get expandedDimensionNote() {
    if (!this._expandedKey) return null;
    const dim = this.dimensions.find(d => d.key === this._expandedKey);
    return dim && dim.hasNote ? dim.note : null;
  }

  get expandedDimensionLabel() {
    if (!this._expandedKey) return '';
    const dim = this.dimensions.find(d => d.key === this._expandedKey);
    return dim ? dim.label : '';
  }

  get expandedDimensionIcon() {
    if (!this._expandedKey) return '';
    const dim = this.dimensions.find(d => d.key === this._expandedKey);
    return dim ? dim.icon : '';
  }

  // ─── Model Picker ──────────────────────────────────────

  get modelOptions() {
    return MODELS.map((m) => ({
      ...m,
      logo: LOGO_MAP[m.logoKey],
      isActive: m.id === this.selectedModelId,
      itemClass: 'model-item' + (m.id === this.selectedModelId ? ' model-item-active' : ''),
      logoClass: 'model-logo' + (m.logoKey === 'openai' ? ' model-logo-openai' : '')
    }));
  }

  get modelBtnClass() {
    return 'model-btn' + (this.isModelPickerOpen ? ' model-btn-open' : '');
  }

  get selectedModelLogo() {
    const model = MODELS.find((m) => m.id === this.selectedModelId);
    return model ? LOGO_MAP[model.logoKey] : LOGO_MAP[MODELS[0].logoKey];
  }

  get selectedModelLogoClass() {
    const model = MODELS.find((m) => m.id === this.selectedModelId);
    const key = model ? model.logoKey : MODELS[0].logoKey;
    return 'model-btn-logo' + (key === 'openai' ? ' model-btn-logo-openai' : '');
  }

  handleModelPickerToggle(event) {
    event.stopPropagation();
    this.isModelPickerOpen = !this.isModelPickerOpen;
  }

  handleModelPickerClose() { this.isModelPickerOpen = false; }

  handleModelSelect(event) {
    event.stopPropagation();
    const newModelId = event.currentTarget.dataset.modelId;
    if (newModelId && newModelId !== this.selectedModelId) {
      this.selectedModelId = newModelId;
    }
    this.isModelPickerOpen = false;
  }

  // ─── Computed ──────────────────────────────────────────

  get loadingTextClass() {
    return 'loading-text' + (this.isTextFading ? ' loading-text-fade' : '');
  }

  get hasAssessment() { return Boolean(this.assessment); }
  get hasError() { return Boolean(this.errorMessage); }
  get showEmptyState() { return !this.isLoadingData && !this.hasAssessment && !this.hasError; }
  get showContent() { return !this.isLoadingData && this.hasAssessment; }

  get showPreAnalysisCta() { return !this.isAnalyzing && !this.showAnalysis; }
  get showAnalysisResult() { return this.showAnalysis && !this.isAnalyzing; }

  get hasRecommendedContact() { return Boolean(this.recommendedContactName); }

  get draftEmailLabel() {
    return 'Draft Email to ' + (this.recommendedContactName || 'Key Contact');
  }

  get overallScore() {
    return this.assessment ? Math.round(this.assessment.overallScore || 0) : 0;
  }

  get overallScoreLabel() {
    const s = this.overallScore;
    if (s >= 8) return 'Strong';
    if (s >= 6) return 'Good';
    if (s >= 4) return 'Moderate';
    return 'At Risk';
  }

  get assessmentDate() { return this.assessment?.assessmentDate || ''; }

  get clariSyncInfo() {
    if (!this.assessment?.syncedFromClari) return '';
    return this.assessment.lastClariSync ? 'Synced: ' + this.assessment.lastClariSync : 'Synced from Clari';
  }

  get analyzeButtonLabel() {
    return this.showAnalysis ? '✨ Re-Analyze' : '✨ Analyze';
  }

  get overallDashOffset() {
    const circumference = 2 * Math.PI * 54;
    return circumference * (1 - this.overallScore / 10);
  }

  get ringStrokeColor() {
    const s = this.overallScore;
    if (s >= 7) return '#2e844a';
    if (s >= 4) return '#e87400';
    return '#c23934';
  }
}
