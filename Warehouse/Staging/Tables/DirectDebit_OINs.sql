CREATE TABLE [Staging].[DirectDebit_OINs] (
    [ID]                             INT           IDENTITY (1, 1) NOT NULL,
    [OIN]                            INT           NOT NULL,
    [Narrative]                      VARCHAR (100) NOT NULL,
    [DirectDebit_StatusID]           TINYINT       NOT NULL,
    [DirectDebit_AssessmentReasonID] TINYINT       NOT NULL,
    [AddedDate]                      DATE          NOT NULL,
    [InternalCategoryID]             INT           NULL,
    [RBSCategoryID]                  INT           NULL,
    [StartDate]                      DATE          NULL,
    [EndDate]                        DATE          NULL,
    [DirectDebit_SupplierID]         INT           NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

