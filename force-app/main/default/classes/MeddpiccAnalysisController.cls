/**
 * Controller for the MEDDPICC Insights LWC.
 * Queries MEDDPICC Assessment data linked to an Account and
 * calls the Models API to produce an AI-powered executive summary.
 */
public without sharing class MeddpiccAnalysisController {

    private static final String DEFAULT_MODEL = 'sfdc_ai__DefaultVertexAIGemini30Flash';

    /**
     * Lightweight wrapper returned to the LWC containing both
     * the raw MEDDPICC data and the AI-generated analysis.
     */
    public class MeddpiccResult {
        @AuraEnabled public List<AssessmentData> assessments;
        @AuraEnabled public String aiAnalysis;
        @AuraEnabled public String error;
        @AuraEnabled public String accountName;
        @AuraEnabled public String opportunityName;
        @AuraEnabled public String recommendedContactName;
    }

    public class AssessmentData {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String assessmentDate;
        @AuraEnabled public String opportunityName;
        @AuraEnabled public String opportunityId;
        @AuraEnabled public Boolean syncedFromClari;
        @AuraEnabled public String lastClariSync;

        @AuraEnabled public String metrics;
        @AuraEnabled public String economicBuyer;
        @AuraEnabled public String decisionCriteria;
        @AuraEnabled public String decisionProcess;
        @AuraEnabled public String paperProcess;
        @AuraEnabled public String identifyPain;
        @AuraEnabled public String champion;
        @AuraEnabled public String competition;

        @AuraEnabled public Decimal scoreMetrics;
        @AuraEnabled public Decimal scoreEconomicBuyer;
        @AuraEnabled public Decimal scoreDecisionCriteria;
        @AuraEnabled public Decimal scoreDecisionProcess;
        @AuraEnabled public Decimal scorePaperProcess;
        @AuraEnabled public Decimal scoreIdentifyPain;
        @AuraEnabled public Decimal scoreChampion;
        @AuraEnabled public Decimal scoreCompetition;
        @AuraEnabled public Decimal overallScore;
    }

    @AuraEnabled
    public static MeddpiccResult getMeddpiccData(Id accountId) {
        MeddpiccResult result = new MeddpiccResult();
        result.assessments = new List<AssessmentData>();

        try {
            Account acct = [
                SELECT Name FROM Account WHERE Id = :accountId LIMIT 1
            ];
            result.accountName = acct.Name;

            List<MEDDPICC_Assessment__c> records = [
                SELECT Id, Name, Assessment_Date__c,
                       Opportunity__c, Opportunity__r.Name,
                       Synced_From_Clari__c, Last_Clari_Sync__c,
                       Metrics__c, Economic_Buyer__c, Decision_Criteria__c,
                       Decision_Process__c, Paper_Process__c, Identify_Pain__c,
                       Champion__c, Competition__c,
                       Score_Metrics__c, Score_Economic_Buyer__c,
                       Score_Decision_Criteria__c, Score_Decision_Process__c,
                       Score_Paper_Process__c, Score_Identify_Pain__c,
                       Score_Champion__c, Score_Competition__c,
                       Overall_Score__c
                FROM MEDDPICC_Assessment__c
                WHERE Account__c = :accountId
                ORDER BY Assessment_Date__c DESC
                LIMIT 10
            ];

            for (MEDDPICC_Assessment__c rec : records) {
                AssessmentData ad = new AssessmentData();
                ad.id = rec.Id;
                ad.name = rec.Name;
                ad.assessmentDate = rec.Assessment_Date__c != null
                    ? rec.Assessment_Date__c.format() : '';
                ad.opportunityName = rec.Opportunity__r != null
                    ? rec.Opportunity__r.Name : '';
                ad.opportunityId = rec.Opportunity__c;
                ad.syncedFromClari = rec.Synced_From_Clari__c;
                ad.lastClariSync = rec.Last_Clari_Sync__c != null
                    ? rec.Last_Clari_Sync__c.format('MMM d, yyyy h:mm a') : '';

                ad.metrics = rec.Metrics__c;
                ad.economicBuyer = rec.Economic_Buyer__c;
                ad.decisionCriteria = rec.Decision_Criteria__c;
                ad.decisionProcess = rec.Decision_Process__c;
                ad.paperProcess = rec.Paper_Process__c;
                ad.identifyPain = rec.Identify_Pain__c;
                ad.champion = rec.Champion__c;
                ad.competition = rec.Competition__c;

                ad.scoreMetrics = rec.Score_Metrics__c;
                ad.scoreEconomicBuyer = rec.Score_Economic_Buyer__c;
                ad.scoreDecisionCriteria = rec.Score_Decision_Criteria__c;
                ad.scoreDecisionProcess = rec.Score_Decision_Process__c;
                ad.scorePaperProcess = rec.Score_Paper_Process__c;
                ad.scoreIdentifyPain = rec.Score_Identify_Pain__c;
                ad.scoreChampion = rec.Score_Champion__c;
                ad.scoreCompetition = rec.Score_Competition__c;
                ad.overallScore = rec.Overall_Score__c;

                result.assessments.add(ad);
            }

            if (!result.assessments.isEmpty()) {
                result.opportunityName = result.assessments[0].opportunityName;
            }

        } catch (Exception e) {
            result.error = e.getMessage();
        }

        return result;
    }

    @AuraEnabled
    public static MeddpiccResult analyzeMeddpicc(Id accountId, String modelName, Id assessmentId) {
        MeddpiccResult data = getMeddpiccData(accountId);

        if (String.isNotBlank(data.error)) {
            return data;
        }
        if (data.assessments.isEmpty()) {
            data.error = 'No MEDDPICC assessments found for this account.';
            return data;
        }

        if (assessmentId != null) {
            String targetId = String.valueOf(assessmentId);
            List<AssessmentData> filtered = new List<AssessmentData>();
            for (AssessmentData ad : data.assessments) {
                if (ad.id == targetId) {
                    filtered.add(ad);
                    break;
                }
            }
            if (!filtered.isEmpty()) {
                data.assessments = filtered;
                data.opportunityName = filtered[0].opportunityName;
            }
        }

        String effectiveModel = String.isNotBlank(modelName)
            ? modelName : DEFAULT_MODEL;

        String prompt = buildPrompt(data);

        try {
            String aiResponse = callModelsAPI(prompt, effectiveModel);
            data.recommendedContactName = extractContact(aiResponse);
            data.aiAnalysis = stripContactMarker(aiResponse);
        } catch (Exception e) {
            data.error = 'AI analysis failed: ' + e.getMessage();
        }

        return data;
    }

    private static String buildPrompt(MeddpiccResult data) {
        List<String> parts = new List<String>();

        parts.add('You are an elite B2B sales strategist specializing in MEDDPICC deal qualification. ');
        parts.add('Analyze the following MEDDPICC assessment data for the account "' + data.accountName + '" ');
        parts.add('and provide an executive-level strategic summary.\n\n');
        parts.add('Today\'s date: ' + Datetime.now().format('MMMM d, yyyy') + '\n\n');

        for (AssessmentData ad : data.assessments) {
            parts.add('## MEDDPICC Assessment: ' + ad.name);
            if (String.isNotBlank(ad.opportunityName)) {
                parts.add(' (Opportunity: ' + ad.opportunityName + ')');
            }
            parts.add('\n');
            if (String.isNotBlank(ad.assessmentDate)) {
                parts.add('Assessment Date: ' + ad.assessmentDate + '\n');
            }
            if (ad.syncedFromClari == true) {
                parts.add('Source: Clari (Last synced: ' + ad.lastClariSync + ')\n');
            }
            parts.add('\n');

            parts.add('### Dimension Scores (0-10)\n');
            parts.add('- Metrics: ' + formatScore(ad.scoreMetrics) + '\n');
            parts.add('- Economic Buyer: ' + formatScore(ad.scoreEconomicBuyer) + '\n');
            parts.add('- Decision Criteria: ' + formatScore(ad.scoreDecisionCriteria) + '\n');
            parts.add('- Decision Process: ' + formatScore(ad.scoreDecisionProcess) + '\n');
            parts.add('- Paper Process: ' + formatScore(ad.scorePaperProcess) + '\n');
            parts.add('- Identify Pain: ' + formatScore(ad.scoreIdentifyPain) + '\n');
            parts.add('- Champion: ' + formatScore(ad.scoreChampion) + '\n');
            parts.add('- Competition: ' + formatScore(ad.scoreCompetition) + '\n');
            parts.add('- Overall: ' + formatScore(ad.overallScore) + '\n\n');

            parts.add('### Detailed Notes\n');
            appendDimension(parts, 'Metrics', ad.metrics);
            appendDimension(parts, 'Economic Buyer', ad.economicBuyer);
            appendDimension(parts, 'Decision Criteria', ad.decisionCriteria);
            appendDimension(parts, 'Decision Process', ad.decisionProcess);
            appendDimension(parts, 'Paper Process', ad.paperProcess);
            appendDimension(parts, 'Identify Pain', ad.identifyPain);
            appendDimension(parts, 'Champion', ad.champion);
            appendDimension(parts, 'Competition', ad.competition);
            parts.add('\n---\n\n');
        }

        parts.add('## OUTPUT INSTRUCTIONS\n\n');
        parts.add('Return clean HTML with inline styles. No markdown. No code fences.\n\n');

        parts.add('USE THIS EXACT STRUCTURE WITH INLINE STYLES:\n\n');

        // Headline
        parts.add('<h2 style="font-size:16px;font-weight:700;color:#032D60;margin:0 0 8px;line-height:1.4">[One punchy deal-health headline]</h2>\n');
        parts.add('<p style="font-size:13px;line-height:1.6;color:#3e3e3c;margin:0 0 16px">[2-3 sentence executive summary. Bold key numbers.]</p>\n\n');

        // Strengths section
        parts.add('<div style="background:#f0fdf4;border-left:3px solid #2e844a;border-radius:0 6px 6px 0;padding:10px 14px;margin:16px 0 8px">\n');
        parts.add('<p style="font-size:11px;font-weight:700;color:#2e844a;text-transform:uppercase;letter-spacing:0.5px;margin:0 0 8px">STRENGTHS</p>\n');
        parts.add('<ul style="margin:0;padding-left:16px"><li style="font-size:13px;line-height:1.5;margin-bottom:6px;color:#3e3e3c">[Dimensions 7+ with why]</li></ul>\n');
        parts.add('</div>\n\n');

        // Risk Areas section
        parts.add('<div style="background:#fef2f2;border-left:3px solid #c23934;border-radius:0 6px 6px 0;padding:10px 14px;margin:16px 0 8px">\n');
        parts.add('<p style="font-size:11px;font-weight:700;color:#c23934;text-transform:uppercase;letter-spacing:0.5px;margin:0 0 8px">RISK AREAS</p>\n');
        parts.add('<ul style="margin:0;padding-left:16px"><li style="font-size:13px;line-height:1.5;margin-bottom:6px;color:#3e3e3c">[Dimensions below 5 with risk and impact]</li></ul>\n');
        parts.add('</div>\n\n');

        // Next Steps section
        parts.add('<div style="background:#eff6ff;border-left:3px solid #0176d3;border-radius:0 6px 6px 0;padding:10px 14px;margin:16px 0 8px">\n');
        parts.add('<p style="font-size:11px;font-weight:700;color:#0176d3;text-transform:uppercase;letter-spacing:0.5px;margin:0 0 8px">RECOMMENDED NEXT STEPS</p>\n');
        parts.add('<ol style="margin:0;padding-left:16px"><li style="font-size:13px;line-height:1.5;margin-bottom:6px;color:#3e3e3c">[Prioritized actions]</li></ol>\n');
        parts.add('</div>\n\n');

        // Competitive Positioning section
        parts.add('<div style="background:#f5f3ff;border-left:3px solid #5c6bc0;border-radius:0 6px 6px 0;padding:10px 14px;margin:16px 0 8px">\n');
        parts.add('<p style="font-size:11px;font-weight:700;color:#5c6bc0;text-transform:uppercase;letter-spacing:0.5px;margin:0 0 8px">COMPETITIVE POSITIONING</p>\n');
        parts.add('<p style="font-size:13px;line-height:1.5;color:#3e3e3c;margin:0">[Competitive analysis]</p>\n');
        parts.add('</div>\n\n');

        // Bottom line callout
        parts.add('<div style="background:#f0f7ff;border-radius:6px;padding:10px 14px;border:1px solid #d1e3f8;margin:16px 0 8px">\n');
        parts.add('<p style="font-size:13px;line-height:1.5;color:#032D60;margin:0"><b>Bottom line:</b> [One sentence deal forecast]</p>\n');
        parts.add('</div>\n\n');

        // Contact marker (hidden, parsed by Apex)
        parts.add('CRITICAL: At the very end of your response, on its own line, add exactly:\n');
        parts.add('[RECOMMENDED_CONTACT:Full Name]\n');
        parts.add('where "Full Name" is the single person you recommend contacting next based on the analysis (e.g. the Champion, Economic Buyer, or key stakeholder). Only one name.\n\n');

        parts.add('FORMATTING RULES:\n');
        parts.add('- Use <b> for scores, key metrics, and important names\n');
        parts.add('- Keep the exact inline styles shown above for each section\n');
        parts.add('- Be specific — reference actual data, not generic advice\n');
        parts.add('- Sound like a strategic advisor, not a database report\n');
        parts.add('- Do NOT mention Salesforce IDs, field API names, or SOQL\n');
        parts.add('- Do NOT wrap the entire output in ```html or ``` fences\n');

        return String.join(parts, '');
    }

    private static void appendDimension(List<String> parts, String label, String value) {
        if (String.isNotBlank(value)) {
            parts.add('**' + label + ':** ' + value + '\n');
        } else {
            parts.add('**' + label + ':** (Not documented)\n');
        }
    }

    private static String formatScore(Decimal score) {
        return score != null ? String.valueOf(score.setScale(0)) + '/10' : 'N/A';
    }

    private static String extractContact(String aiResponse) {
        if (String.isBlank(aiResponse)) return null;
        Pattern p = Pattern.compile('\\[RECOMMENDED_CONTACT:([^\\]]+)\\]');
        Matcher m = p.matcher(aiResponse);
        return m.find() ? m.group(1).trim() : null;
    }

    private static String stripContactMarker(String aiResponse) {
        if (String.isBlank(aiResponse)) return aiResponse;
        return aiResponse.replaceAll('\\[RECOMMENDED_CONTACT:[^\\]]*\\]', '').trim();
    }

    private static String callModelsAPI(String promptText, String modelName) {
        aiplatform.ModelsAPI.createGenerations_Request request =
            new aiplatform.ModelsAPI.createGenerations_Request();
        request.modelName = modelName;

        aiplatform.ModelsAPI_GenerationRequest requestBody =
            new aiplatform.ModelsAPI_GenerationRequest();
        request.body = requestBody;
        requestBody.prompt = promptText;

        aiplatform.ModelsAPI modelsAPI = new aiplatform.ModelsAPI();
        aiplatform.ModelsAPI.createGenerations_Response response =
            modelsAPI.createGenerations(request);

        if (response.Code200 != null && response.Code200.generation != null) {
            return response.Code200.generation.generatedText;
        }
        return '<p>No response received from AI model.</p>';
    }
}
