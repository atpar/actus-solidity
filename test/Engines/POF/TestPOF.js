const TestPOF = artifacts.require('TestPOF.sol');
const PAMEngine = artifacts.require('PAMEngine.sol');
const { getDefaultTestTerms } = require('../../helper/tests');
const { parseTermsToLifecycleTerms } = require('../../helper/parser');

contract('TestPOF', () => {
    before(async () => {       
        this.PAMEngineInstance = await PAMEngine.new(); 
        this.terms = await getDefaultTestTerms('PAM');
        this.lifecycleTerms = parseTermsToLifecycleTerms(this.terms);
        this.TestPOF = await TestPOF.new();
    });

    /*
    * TEST POF_PAM_FP
    */

    // feeBasis.A
    it('PAM fee basis A: should yield a fee of 5', async () => {
        const state = await this.PAMEngineInstance.computeInitialState(this.lifecycleTerms, {});
        const externalData = "0x0000000000000000000000000000000000000000000000000000000000000000";
        const scheduleTime = 0;

        this.lifecycleTerms.feeBasis = 0; // FeeBasis.A
        this.lifecycleTerms.feeRate = web3.utils.toWei("5"); // set fixed fee
        this.lifecycleTerms.contractRole = 0; //RPA -> roleSign = 1
        
        const payoff = await this.TestPOF._POF_PAM_FP(
            this.lifecycleTerms, 
            state, 
            scheduleTime, 
            externalData 
            );
        assert.equal(payoff.toString(), "5000000000000000000");
    });

    // feeBasis.N
    it('PAM fee basis N: should yield a fee of 10100', async () => {
        const state = await this.PAMEngineInstance.computeInitialState(this.lifecycleTerms, {});
        const externalData = "0x0000000000000000000000000000000000000000000000000000000000000000";
        const scheduleTime = 6307200; // .2 years

        //console.log(this.lifecycleTerms)
        //console.log(state)

        this.lifecycleTerms.feeBasis = 1; // FeeBasis.N
        state[7] = web3.utils.toWei("100"); // feeAccrued = 100
        state[1] = '0'; // statusDate = 0
        this.lifecycleTerms.businessDayConvention = 0; // NULL
        this.lifecycleTerms.calendar = 0; // NoCalendar
        this.lifecycleTerms.dayCountConvention = 2; // A_365
        this.lifecycleTerms.maturityDate = 31536000; // 1 year

        this.lifecycleTerms.feeRate = web3.utils.toWei(".05"); // set fee rate
        state[5] = web3.utils.toWei("1000000"); // notionalPrincipal = 1M
        
        const payoff = await this.TestPOF._POF_PAM_FP(
            this.lifecycleTerms, 
            state, 
            scheduleTime, 
            externalData 
            );
        assert.equal(payoff.toString(), "10100000000000000000000");
    });

    /*
    * TEST POF_PAM_IED
    */

    it('Should yield an initial exchange amount of -1000100', async () => {
        const state = await this.PAMEngineInstance.computeInitialState(this.lifecycleTerms, {});
        const externalData = "0x0000000000000000000000000000000000000000000000000000000000000000";
        scheduleTime = 0;

        this.lifecycleTerms.contractRole = 0; //RPA -> roleSign = 1
        this.lifecycleTerms.notionalPrincipal = web3.utils.toWei("1000000"); // notionalPrincipal = 1M
        this.lifecycleTerms.premiumDiscountAtIED = web3.utils.toWei("100"); // premiumDiscountAtIED = 100

        const payoff = await this.TestPOF._POF_PAM_IED(
            this.lifecycleTerms, 
            state, 
            scheduleTime, 
            externalData 
            );
        assert.equal(payoff.toString(), "-1000100000000000000000000");
    });

    /*
    * TEST POF_PAM_IP
    */

    it('Should yield an interest payment of 20200', async () => {
        const state = await this.PAMEngineInstance.computeInitialState(this.lifecycleTerms, {});
        const externalData = "0x0000000000000000000000000000000000000000000000000000000000000000";
        const scheduleTime = 6307200; // .2 years

        state[9] = web3.utils.toWei("2"); // interestScalingMultiplier
        state[6] = web3.utils.toWei("100"); // accruedInterest = 
        state[1] = '0'; // statusDate = 0
        this.lifecycleTerms.businessDayConvention = 0; // NULL
        this.lifecycleTerms.calendar = 0; // NoCalendar
        this.lifecycleTerms.dayCountConvention = 2; // A_365
        this.lifecycleTerms.maturityDate = 31536000; // 1 year
        state[8] = web3.utils.toWei("0.05"); // nominalInterestRate
        state[5] = web3.utils.toWei("1000000"); // notionalPrincipal = 1M

        const payoff = await this.TestPOF._POF_PAM_IP(
            this.lifecycleTerms, 
            state, 
            scheduleTime, 
            externalData 
            );
        assert.equal(payoff.toString(), "20200000000000000000000");
    });
    
});
