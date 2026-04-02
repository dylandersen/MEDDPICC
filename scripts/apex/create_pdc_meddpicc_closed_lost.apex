MEDDPICC_Assessment__c assess = new MEDDPICC_Assessment__c();
assess.put('Account__c', '001Hu00003ccrTbIAI');
assess.put('Opportunity__c', '006Hu00001k8zvFIAQ');
assess.put('Assessment_Date__c', Date.newInstance(2025, 11, 15));
assess.put('Synced_From_Clari__c', true);
assess.put('Last_Clari_Sync__c', Datetime.newInstance(2025, 11, 17, 9, 45, 0));

// Metrics — never properly quantified
assess.put('Metrics__c', 'The steel supply consolidation was projected to save $20K annually by reducing the number of vendors from 4 to 2. However, this was a rough estimate provided by the procurement coordinator with no formal analysis. We never built a proper ROI model or TCO comparison. The savings were marginal and did not create urgency — the existing suppliers were "good enough" in the eyes of most stakeholders.');
assess.put('Score_Metrics__c', 2);

// Economic Buyer — never identified
assess.put('Economic_Buyer__c', 'We assumed the Procurement Manager, David Chen, had budget authority. He did not. The actual budget holder was the VP of Supply Chain who we never met. Chen could only recommend up to $10K discretionary spend. The $20K deal required VP approval and we learned this too late in the cycle — by the time we requested an introduction, the VP had already decided to stay with the incumbent.');
assess.put('Score_Economic_Buyer__c', 1);

// Decision Criteria — misaligned
assess.put('Decision_Criteria__c', 'We focused our pitch on quality certifications and delivery reliability, but PDC was primarily evaluating on price and existing relationship strength. The incumbent supplier had been with PDC for 12 years and offered a 5% price match when they learned about our proposal. Our premium pricing ($18/unit vs incumbent $15.50/unit) was the primary objection and we had no differentiated value story to justify the gap.');
assess.put('Score_Decision_Criteria__c', 3);

// Decision Process — informal and opaque
assess.put('Decision_Process__c', 'There was no formal evaluation process. David Chen collected two quotes (us and one other challenger) and presented them alongside the incumbent renewal to his VP in a single email. No demo, no technical evaluation, no committee review. The decision was made in a 15-minute conversation between Chen and the VP. We were not aware the timeline had accelerated until we received the "we went another direction" email.');
assess.put('Score_Decision_Process__c', 2);

// Paper Process — never reached this stage
assess.put('Paper_Process__c', 'We prepared a standard supply agreement and sent it to Chen for review, but it was never forwarded to legal or procurement. The deal was rejected before any contract negotiation began. In hindsight, the fact that they never engaged on contract terms was a signal that we were not the preferred vendor.');
assess.put('Score_Paper_Process__c', 1);

// Identify Pain — surface-level only
assess.put('Identify_Pain__c', 'Chen mentioned occasional quality issues with one of their four steel suppliers — some shipments arrived with surface defects that required re-inspection. However, this was a minor inconvenience, not a business-critical pain. The defect rate was under 2% and the incumbent handled replacements promptly. We failed to uncover a compelling pain that would justify switching suppliers and absorbing the transition costs.');
assess.put('Score_Identify_Pain__c', 3);

// Champion — no real champion
assess.put('Champion__c', 'David Chen was friendly and responsive but was not a true champion. He was gathering quotes as part of a routine vendor review cycle, not because he was advocating for change. He never sold internally on our behalf, never shared competitive intel, and never coached us on how to win. When the VP chose the incumbent, Chen accepted the decision without pushback. We had no internal advocate with influence.');
assess.put('Score_Champion__c', 1);

// Competition — incumbent won easily
assess.put('Competition__c', 'The incumbent, National Steel Supply, had a 12-year relationship with PDC including volume-based pricing tiers, dedicated account management, and consignment inventory at two PDC facilities. When threatened, they offered a 5% discount and extended payment terms to Net-60. We had no relationship equity and our pricing was 16% higher. The incumbent also had the VP of Supply Chain relationship — they played golf together quarterly. We never had a realistic competitive position.');
assess.put('Score_Competition__c', 2);

insert assess;
System.debug('Created Closed Lost assessment: ' + assess.Id);

MEDDPICC_Assessment__c verify = [SELECT Id, Name, Overall_Score__c FROM MEDDPICC_Assessment__c WHERE Id = :assess.Id];
System.debug('Record: ' + verify.Name + ' | Overall Score: ' + verify.Overall_Score__c);
