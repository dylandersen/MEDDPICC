MEDDPICC_Assessment__c assess = new MEDDPICC_Assessment__c();
assess.put('Account__c', '001Hu00003ccrTbIAI');
assess.put('Opportunity__c', '006Hu00001k9BOEIA2');
assess.put('Assessment_Date__c', Date.newInstance(2026, 3, 18));
assess.put('Synced_From_Clari__c', true);
assess.put('Last_Clari_Sync__c', Datetime.newInstance(2026, 3, 31, 14, 22, 0));

// Metrics — decent but not fully quantified
assess.put('Metrics__c', 'PDC projects $1.35M annual savings from consolidating 3 legacy warehouse management platforms into one. They estimate 40% reduction in IT maintenance overhead and 15% improvement in order fulfillment speed. However, the ROI model has not been validated by Finance — it was built by the operations team and CFO has not signed off on the assumptions. Time-to-value is estimated at 14 months which is longer than the board wants.');
assess.put('Score_Metrics__c', 6);

// Economic Buyer — identified but not engaged
assess.put('Economic_Buyer__c', 'CFO Karen Liu controls budget but has been difficult to engage directly. All communication has been routed through VP of Operations Rivera. Liu attended the initial demo 4 months ago but has not been in any meetings since. She reportedly has concerns about the implementation timeline conflicting with their ERP migration scheduled for Q4. We have not been able to present the business case directly to her.');
assess.put('Score_Economic_Buyer__c', 4);

// Decision Criteria — strong alignment on paper
assess.put('Decision_Criteria__c', 'Technical evaluation scored our platform 92/100 against their requirements. Key criteria include: multi-site inventory visibility, real-time shipping integration with FedEx/UPS APIs, role-based access controls meeting SOC2 compliance, and the ability to handle 50K+ SKUs. We meet all primary requirements. Secondary criteria around custom reporting dashboards are partially met — they want embedded BI which requires our premium tier.');
assess.put('Score_Decision_Criteria__c', 8);

// Decision Process — this is where they are stuck
assess.put('Decision_Process__c', 'The RFP was issued 3 months ago with a stated decision timeline of 6 weeks. We are now 12 weeks in with no decision. The evaluation committee (5 members) completed technical scoring but the process stalled at the executive review stage. VP Rivera says the procurement committee meets monthly and we missed the March cycle due to incomplete security questionnaire responses. The April meeting agenda is not confirmed. There may be an internal reorganization affecting the operations division that is creating uncertainty.');
assess.put('Score_Decision_Process__c', 3);

// Paper Process — major blocker
assess.put('Paper_Process__c', 'Legal review has not started. PDC requires all vendors to complete a 200-question security assessment, data processing agreement, and liability review before contracts can be drafted. We submitted the security questionnaire but received feedback that 14 answers were insufficient and need to be re-done with their new CISO (hired 6 weeks ago) who has stricter requirements than the predecessor. MSA redlines have not begun. Their legal team reportedly has a 4-6 week turnaround on contract reviews.');
assess.put('Score_Paper_Process__c', 2);

// Identify Pain — well understood
assess.put('Identify_Pain__c', 'PDC is running three separate warehouse management systems across 8 distribution centers following acquisitions in 2023 and 2024. This causes: (1) inventory discrepancies averaging $180K/quarter in write-offs, (2) inability to transfer stock between facilities in real-time, (3) 23% of orders require manual intervention due to system incompatibilities. Their largest client, Target, has threatened to reduce allocation by 30% if fulfillment accuracy does not improve by Q1 2027.');
assess.put('Score_Identify_Pain__c', 9);

// Champion — engaged but losing influence
assess.put('Champion__c', 'VP of Operations Marco Rivera has been our primary champion for 5 months. He built the internal business case and drove the RFP process. However, his influence may be waning — the rumored reorg could move warehouse operations under a new SVP of Supply Chain (external hire expected in May). Rivera has told us privately he is frustrated with the slow procurement process and is worried the project will lose momentum. He has not been able to get us a meeting with the CFO in 8 weeks.');
assess.put('Score_Champion__c', 5);

// Competition — Oracle is lurking
assess.put('Competition__c', 'Oracle WMS was included in the RFP and scored 78/100 on technical evaluation (vs our 92). However, PDC already runs Oracle ERP and the Oracle team is pushing a bundled discount narrative — "add WMS to your existing Oracle contract for 35% less." The new CISO reportedly prefers Oracle because it reduces the vendor security footprint. We have not seen Oracle present to the executive team but Rivera confirmed they had a separate meeting with the CFO that we were not invited to.');
assess.put('Score_Competition__c', 4);

insert assess;
System.debug('Created RFP Stuck assessment: ' + assess.Id);

MEDDPICC_Assessment__c verify = [SELECT Id, Name, Overall_Score__c FROM MEDDPICC_Assessment__c WHERE Id = :assess.Id];
System.debug('Record: ' + verify.Name + ' | Overall Score: ' + verify.Overall_Score__c);
