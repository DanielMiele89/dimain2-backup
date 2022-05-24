CREATE TABLE [SmartEmail].[SolusCharityEmail_NET] (
    [ClubID]                   INT            NOT NULL,
    [ClubName]                 NVARCHAR (100) NOT NULL,
    [IsLoyalty]                TINYINT        NULL,
    [Loyalty]                  VARCHAR (7)    NOT NULL,
    [FanID]                    INT            NOT NULL,
    [EmailGroup]               INT            NOT NULL,
    [SmartEmailSendID]         INT            NULL,
    [CustomerRankByEmailGroup] BIGINT         NULL
);

