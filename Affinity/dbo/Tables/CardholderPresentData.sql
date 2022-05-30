CREATE TABLE [dbo].[CardholderPresentData] (
    [CardholderPresentData] INT         NULL,
    [Recode]                VARCHAR (1) NULL
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Cardholder Present Flag values to recode into letters', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CardholderPresentData';


GO
EXECUTE sp_addextendedproperty @name = N'Related_Process', @value = 'Client Data Pipeline', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CardholderPresentData';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'The CardholderPresentData as held on the transaction', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CardholderPresentData', @level2type = N'COLUMN', @level2name = N'CardholderPresentData';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'The required value to recode the CardholderPresentData to for client facing files', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CardholderPresentData', @level2type = N'COLUMN', @level2name = N'Recode';

