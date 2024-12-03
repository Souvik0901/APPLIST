public void execute(){
  try{
       id = currentUserId = UserInfo.getUserId();
       List<BrAppListWrapper> appList = new List<BrAppListWrapper>();

       conId = [SELECT Id,
                       Email,
                       ContactId
                FROM User 
                WHERE Id =:currentUserId].ContactId;

       if(!BrokerPortalSecurityUtil.profileChecking(currentUserId) && !BrokerPortalSecurityUtil.brokerAccessChecking()){
                throw new CustomException(CpConstants.ACCESS_DENIED);
        }
        appList = searchByStatus(status,conId);
        if(appList.size()==CpConstants.ZERO){
                throw new CustomException(CpConstants.QQLIST_MISSING);
        }
        List<clcommon.PortalCustomRemoteActionRecord> respList = new List<clcommon.PortalCustomRemoteActionRecord>();
        for(BrAppListWrapper appObj : appList){
                String jsonString = JSON.serialize(appObj);
                Map<String, Object> appMap = (Map<String, Object>)JSON.deserializeUntyped(jsonString);
                respList.add(new clcommon.PortalCustomRemoteActionRecord(appMap));
        }

         res = clcommon.PortalActions.getCustomRemoteActionResponse(respList);
            res.status = ResponseMessenger.success;  
  }


  catch(Exception e){
        List<clcommon.PortalCustomRemoteActionRecord> resRecords = new List<clcommon.PortalCustomRemoteActionRecord>();
        ExceptionManager.manageException(e);
        if(e.getMessage() == CpConstants.QQLIST_MISSING){
            List<clcommon.PortalCustomRemoteActionRecord> respList = new List<clcommon.PortalCustomRemoteActionRecord>();
            res = clcommon.PortalActions.getCustomRemoteActionResponse(respList);
        }else if(e.getTypeName().equals(ConstantValues.CUSTOMEXCEPTIONTYPE)){
            res = FlowfiUtil.getErrorMessageResponse(e.getMessage());
        }else {
            res = FlowfiUtil.getErrorResponse(ResponseMessenger.genericExceptionMsg);
        }
        insert ExceptionManager.getClCommonLog(e,ConversionConstant.genesis);
  }

}
