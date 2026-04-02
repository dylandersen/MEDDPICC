// Create a realistic MEDDPICC Assessment record for Pacific Distribution Centers (PDC)

Id accountId = '001Hu00003ccrTbIAI';

MEDDPICC_Assessment__c assessment = new MEDDPICC_Assessment__c();
assessment.put('Account__c', accountId);
assessment.put('Assessment_Date__c', Date.today().addDays(-3));
assessment.put('Synced_From_Clari__c', true);
assessment.put('Last_Clari_Sync__c', Datetime.now().addHours(-6));

assessment.put('Metrics__c', 'PDC projects a 22% reduction in order fulfillment cycle time (from 4.5 days to 3.5 days) by migrating their warehouse management and logistics orchestration to the cloud. This translates to an estimated $3.2M annual savings in operational costs and a 15% improvement in on-time delivery rates. Current manual processes cause approximately $850K/year in mis-shipments and re-routing costs. ROI target: 18-month payback on the $250K investment.');

assessment.put('Economic_Buyer__c', 'Karen Liu, CFO — confirmed as the economic buyer with final sign-off authority on all IT investments above $100K. She has been engaged in 3 executive briefings and expressed strong interest in the operational cost reduction metrics. She has asked her team to model the TCO comparison. Budget is allocated from the FY26 digital transformation fund. Risk: Karen is also evaluating two other large capital projects that compete for the same budget pool.');

assessment.put('Decision_Criteria__c', 'Technical: (1) Real-time inventory visibility across 12 distribution centers, (2) API-first architecture for ERP integration with their SAP system, (3) 99.95% uptime SLA, (4) Sub-200ms response time for order routing decisions. Business: (1) ROI within 18 months, (2) Phased rollout starting with West Coast facilities, (3) No disruption to holiday peak season operations (Oct-Dec). Financial: (1) Subscription model preferred over large CapEx, (2) Must include implementation and training.');

assessment.put('Decision_Process__c', 'Four-stage process confirmed by VP of Operations: (1) Technical evaluation — IT team completes proof-of-concept by mid-April, (2) Business case review — Operations leadership validates ROI model, (3) Executive committee presentation — CFO Karen Liu and COO present to board in May, (4) Procurement and legal — standard MSA review, estimated 3 weeks. Timeline is aggressive due to wanting to go live before Q4 peak season. Key risk: Board meeting may be delayed if Q1 earnings miss expectations.');

assessment.put('Paper_Process__c', 'PDC uses a standard procurement process through their purchasing department. MSA template has been shared and is under initial legal review. Key terms to negotiate: (1) Data residency requirements — PDC needs US-only hosting for compliance, (2) Liability caps — their legal team typically pushes for 2x annual contract value, (3) SLA penalties — want financial credits for downtime beyond SLA. Estimated timeline: 2-3 weeks for red-lining, 1 week for final signatures. Procurement contact is Lisa Park, Director of Purchasing.');

assessment.put('Identify_Pain__c', 'CRITICAL: PDC\'s legacy on-premise WMS is end-of-life with no vendor support after December 2026. They are experiencing: (1) 20% order fulfillment delays during peak periods causing $2.1M in SLA penalties to their retail clients, (2) No real-time visibility into inventory across their 12 distribution centers, forcing manual reconciliation that takes 3 FTEs full-time, (3) Integration failures between WMS and SAP ERP causing $850K/year in mis-shipments, (4) Inability to scale for their recent partnership with a major e-commerce retailer that will increase volume by 40%. The pain is urgent — their largest retail client (representing 30% of revenue) has threatened to move to a competitor if delivery performance doesn\'t improve by Q4.');

assessment.put('Champion__c', 'Marcus Rivera, VP of Operations — strong internal champion who initiated the cloud migration evaluation. He has been burned by the legacy system failures and has personal credibility on the line with the board for the digital transformation initiative. Marcus has: (1) Organized all executive briefings, (2) Shared internal stakeholder map and org chart, (3) Provided competitor intel on what Oracle is proposing, (4) Scheduled a site visit to their LA distribution center for our technical team. Risk factor: Marcus is relatively new (18 months at PDC) and may not have the deep political capital of a longer-tenured executive.');

assessment.put('Competition__c', 'PRIMARY COMPETITOR: Oracle Supply Chain Cloud — they have an existing relationship through PDC\'s SAP ERP (Oracle DB layer). Oracle is proposing a bundled deal with significant discounts on the database renewal. Their proposal is $310K over 3 years vs our $250K. SECONDARY: Manhattan Associates — strong in WMS but weaker on the cloud migration story. OUR DIFFERENTIATION: (1) Faster implementation timeline (12 weeks vs Oracle\'s 6 months), (2) Superior API-first architecture for SAP integration, (3) Better real-time analytics and dashboarding, (4) Stronger customer references in distribution/logistics vertical. RISK: Oracle has a C-level executive sponsor relationship with PDC\'s CEO from a previous company.');

assessment.put('Score_Metrics__c', 8);
assessment.put('Score_Economic_Buyer__c', 7);
assessment.put('Score_Decision_Criteria__c', 7);
assessment.put('Score_Decision_Process__c', 6);
assessment.put('Score_Paper_Process__c', 4);
assessment.put('Score_Identify_Pain__c', 9);
assessment.put('Score_Champion__c', 8);
assessment.put('Score_Competition__c', 5);

insert assessment;

// Link to the Cloud Migration Project opportunity
assessment.put('Opportunity__c', '006Hu00001kAqv1IAC');
update assessment;

System.debug('Created MEDDPICC Assessment: ' + assessment.Id + ' (' + assessment.get('Name') + ')');
System.debug('Account: Pacific Distribution Centers (PDC)');
System.debug('Opportunity: Cloud Migration Project');
