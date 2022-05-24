CREATE TABLE [Derived].[__SFD_PostUploadAssessmentData_Member_Archived] (
    [MemberID]    INT IDENTITY (1, 1) NOT NULL,
    [FanID]       INT NOT NULL,
    [LionSendID]  INT NOT NULL,
    [OfferSlot]   INT NOT NULL,
    [IronOfferID] INT NOT NULL,
    CONSTRAINT [pk_MemberID] PRIMARY KEY CLUSTERED ([MemberID] ASC) WITH (FILLFACTOR = 100)
);

