public Static List<BrAppListWrapper>  searchByStatus (String statusCheck, Id conId){
      List<String> statusList = new List<String>();

       if(statusCheck == CpConstants.ALL_CAPS){
            String constant = CpConstants.BROKER_FEATURE_STATUS_MASKED;
            statusList = constant.split(CpConstants.COMA);
       }else {
            statusList.add(statusCheck);
        }
       
       List<genesis__Applications__c> appList = [SELECT Id,
                                                            Name,
                                                            Full_Name__c,
                                                            Last_Name__c,
                                                            RecordTypeId,
                                                            Loan_Term__c,
                                                            First_Name__c,
                                                            Product_Name__c,
                                                            Status_labels__c,
                                                            Creation_Date__c,
                                                            genesis__Term__c ,
                                                            genesis__Status__c,
                                                            Income_Verified__c,
                                                            Borrower_Email__c,
                                                            Loan_Purposes__c,
                                                            Asset_Type__c,
                                                            genesis__Loan_Amount__c,
                                                            Send_Link_to_applicant__c,
                                                            genesis__Interest_Rate__c,
                                                            genesis__CL_Product_Name__c,
                                                            Letter_of_Offer_Downloaded__c,
                                                            Auto_Loan_Purpose__c,
                                                            Asset_being_financed__c,
                                                            Broker_Accept_Manual_Document_Upload_T_C__c,
                                                            AdobeSignParty__c,
                                                            Joint_Application__c,
                                                            Status_Formula__c ,
                                                            Drivers_Licence_Not_Available__c,
                                                            owner.name,
                                                            OwnerId,
                                                            // Added the field to be sent into the broker portal as per ML Aggregator API Dev
                                                            Submitted_Via_Aggregator_API__c,
                                                            Biometric_Results__c
                                                            FROM genesis__Applications__c 
                                                            WHERE Broker_Contact__c =:conId
                                                            AND Broker_Application__c = true
                                                            AND Status_Formula__c IN:statusList
                                                            AND Top_Up__c = false
                                                            AND CreatedDate = LAST_N_MONTHS:12
                                                            WITH SECURITY_ENFORCED
                                                            ORDER BY Creation_Date__c DESC];

//Status filter is removed as there is no such Application Status (Specific for Outstanding Actions)                                                   
        List<genesis__Applications__c> appListForOutTasks = [SELECT Id,
                                                            Name,
                                                            Full_Name__c,
                                                            Last_Name__c,
                                                            RecordTypeId,
                                                            Loan_Term__c,
                                                            First_Name__c,
                                                            Product_Name__c,
                                                            Status_labels__c,
                                                            Creation_Date__c,
                                                            genesis__Term__c ,
                                                            genesis__Status__c,
                                                            Income_Verified__c,
                                                            Borrower_Email__c,
                                                            Loan_Purposes__c,
                                                            Asset_Type__c,
                                                            genesis__Loan_Amount__c,
                                                            Send_Link_to_applicant__c,
                                                            genesis__Interest_Rate__c,
                                                            genesis__CL_Product_Name__c,
                                                            Letter_of_Offer_Downloaded__c,
                                                            Auto_Loan_Purpose__c,
                                                            Asset_being_financed__c,
                                                            Broker_Accept_Manual_Document_Upload_T_C__c,
                                                            AdobeSignParty__c,
                                                            Drivers_Licence_Not_Available__c,
                                                            Joint_Application__c,
                                                            Status_Formula__c,
                                                            Broker_Contact__c,
                                                            OwnerId,
                                                            owner.name,

                                                            // Added the field to be sent into the broker portal as per ML Aggregator API Dev
                                                            Submitted_Via_Aggregator_API__c,
                                                            Biometric_Results__c
                                                            FROM genesis__Applications__c 
                                                            WHERE Broker_Contact__c =:conId
                                                            AND Broker_Application__c = true
                                                            AND OwnerId = :UserInfo.getUserId()
                                                            AND Top_Up__c = false
                                                            AND CreatedDate = LAST_N_MONTHS:12
                                                            WITH SECURITY_ENFORCED
                                                            ORDER BY Creation_Date__c DESC];

     Map<Id,genesis__Applications__c> appIDMap;
        if(statusCheck == OUTSTANDING_ACTIONS){
            appIDMap= new Map<Id,genesis__Applications__c>(appListForOutTasks);
        }
        else{
            appIDMap= new Map<Id,genesis__Applications__c>(appList);
        }

   List<Task> taskList;

   if(statusCheck == OUTSTANDING_ACTIONS){
            taskList = [SELECT Id,
                                Status,
                                genesis__Application__c,
                                genesis__Application__r.Name 
                                FROM Task 
                                WHERE genesis__Application__c IN :appListForOutTasks 
                                AND (Broker_Task__c = true OR Approval_Task__c = true)
                                WITH SECURITY_ENFORCED
                                ORDER BY genesis__Application__r.Name DESC];
        }
        else{
            taskList = [SELECT Id,
                                Status,
                                genesis__Application__c,
                                genesis__Application__r.Name 
                                FROM Task 
                                WHERE genesis__Application__c 
                                IN :appList 
                                AND (Broker_Task__c = true 
                                OR Approval_Task__c = true) 
                                WITH SECURITY_ENFORCED
                                ORDER BY genesis__Application__r.Name DESC];
        } 

    List<genesis__applications__c> sortedAppList = new List<genesis__applications__c>(); 
    List<BrAppListWrapper> finalList = new List<BrAppListWrapper>();

    //mapping of app and contact for appListForOutTasks
        Map<Id,Id> appConMap = new Map<Id,Id>();
        for(genesis__applications__c app : appListForOutTasks){
            appConMap.put(app.Id,app.OwnerId);
        }


        Id currUser = UserInfo.getUserId();

        //List of Pending task applications
        for(Task tsk : taskList ){
            if(tsk.Status != COMPLETED_STATUS && !sortedAppList.contains(appIdMap.get(tsk.genesis__Application__c)) && appConMap.get(tsk.genesis__Application__c) ==currUser){
                sortedAppList.add(appIdMap.get(tsk.genesis__Application__c));
            }
        }

        for(genesis__applications__c app : sortedAppList){
            BrAppListWrapper obj = new BrAppListWrapper();
                obj.Id = app.Id;
                obj.recordTypeId = app.RecordTypeId;
                obj.Name = app.Name;
                obj.fullName = app.Full_Name__c;
                obj.fName = app.First_Name__c;
                obj.lName = app.Last_Name__c;
                obj.productName = app.Product_Name__c;
                obj.statusLabels = app.Status_labels__c;
                obj.genesisStatus = app.genesis__Status__c;
                obj.borrowerEmail = app.Borrower_Email__c;
                obj.loanPurposes = app.Loan_Purposes__c;
                obj.assetType = app.Asset_Type__c;
                obj.genesisProdName = app.genesis__CL_Product_Name__c;
                obj.autoLoanPurpose = app.Auto_Loan_Purpose__c;
                obj.brManualDocUpConsent = app.Broker_Accept_Manual_Document_Upload_T_C__c;
                obj.adobeSignParty = app.AdobeSignParty__c;
                obj.statusFormula = app.Status_Formula__c;
                obj.loanTerm = app.Loan_Term__c;
                obj.AssetBeingFinanced = app.Asset_being_financed__c;
                obj.genesisTerm = app.genesis__Term__c ;
                obj.creationDate = app.Creation_Date__c;
                obj.incomeVerified = app.Income_Verified__c;
                obj.sendLinkToApplicant = app.Send_Link_to_applicant__c;
                obj.letterOfOfferDownloaded = app.Letter_of_Offer_Downloaded__c;
                obj.jointApp = app.Joint_Application__c;
                obj.loanAmount = app.genesis__Loan_Amount__c;
                obj.interestRate = app.genesis__Interest_Rate__c;
                obj.DriverLicenceAvailable = app.Drivers_Licence_Not_Available__c;
                obj.ownerName = app.owner.name;
                obj.isOutStandingApp = true;
                // Check whether the Application was submitted via the Aggregator API or not
                obj.isAggregatorApiApp = (app.Submitted_Via_Aggregator_API__c) ? AggregatorConstants.YES : AggregatorConstants.NO;
                obj.biometricResult = app.Biometric_Results__c;
                finalList.add(obj);
            
        }

        //List of Non-pending and no task applications
        if(statusCheck != OUTSTANDING_ACTIONS){
            for(genesis__applications__c app : appList ){
                if(!sortedAppList.contains(app)){
                    BrAppListWrapper obj = new BrAppListWrapper();
                    obj.Id = app.Id;
                    obj.recordTypeId = app.RecordTypeId;
                    obj.Name = app.Name;
                    obj.fullName = app.Full_Name__c;
                    obj.fName = app.First_Name__c;
                    obj.lName = app.Last_Name__c;
                    obj.productName = app.Product_Name__c;
                    obj.statusLabels = app.Status_labels__c;
                    obj.genesisStatus = app.genesis__Status__c;
                    obj.borrowerEmail = app.Borrower_Email__c;
                    obj.loanPurposes = app.Loan_Purposes__c;
                    obj.assetType = app.Asset_Type__c;
                    obj.genesisProdName = app.genesis__CL_Product_Name__c;
                    obj.autoLoanPurpose = app.Auto_Loan_Purpose__c;
                    obj.brManualDocUpConsent = app.Broker_Accept_Manual_Document_Upload_T_C__c;
                    obj.adobeSignParty = app.AdobeSignParty__c;
                    obj.statusFormula = app.Status_Formula__c;
                    obj.loanTerm = app.Loan_Term__c;
                    obj.genesisTerm = app.genesis__Term__c ;
                    obj.creationDate = app.Creation_Date__c;
                    obj.AssetBeingFinanced = app.Asset_being_financed__c;
                    obj.incomeVerified = app.Income_Verified__c;
                    obj.sendLinkToApplicant = app.Send_Link_to_applicant__c;
                    obj.letterOfOfferDownloaded = app.Letter_of_Offer_Downloaded__c;
                    obj.jointApp = app.Joint_Application__c;
                    obj.loanAmount = app.genesis__Loan_Amount__c;
                    obj.interestRate = app.genesis__Interest_Rate__c;
                    obj.DriverLicenceAvailable = app.Drivers_Licence_Not_Available__c;
                    obj.ownerName = app.owner.name;
                    obj.isOutStandingApp = false;
                    // Check whether the Application was submitted via the Aggregator API or not
                    obj.isAggregatorApiApp = (app.Submitted_Via_Aggregator_API__c) ? AggregatorConstants.YES : AggregatorConstants.NO;
                    obj.biometricResult = app.Biometric_Results__c;
                    finalList.add(obj);
                }
            }

             

}