const TestPOF = artifacts.require('TestPOF.sol');
const PAMEngine = artifacts.require('PAMEngine.sol');
const { getDefaultTestTerms } = require('../helper/tests');
const { parseTermsToLifecycleTerms } = require('../helper/parser');

contract('TestPOF', () => {
    before(async () => {       
        this.PAMEngineInstance = await PAMEngine.new(); 
        this.terms = await getDefaultTestTerms('PAM');
        this.lifecycleTerms = parseTermsToLifecycleTerms(this.terms);
        this.initialState = await this.PAMEngineInstance.computeInitialState(this.lifecycleTerms, {});
        this.TestPOF = await TestPOF.new();
    });

    it('should work', async () => {
            this.TestPOF._POF_PAM_FP(this.lifecycleTerms, this.initialState, 0, "" );
    });

});
