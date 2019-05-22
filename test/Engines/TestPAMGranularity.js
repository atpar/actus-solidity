// const PAMEngine = artifacts.require('PAMEngine.sol')

// const { parseTermsFromPath } = require('../../actus-resources/parser')
// const PAMTestTermsPath = './actus-resources/test-terms/pam-test-terms-granular.csv'

// const getTerms = () => {
//   return parseTermsFromPath(PAMTestTermsPath)
// }

// contract('PAMEngine', () => {

//   before(async () => {        
//     this.PAMEngineInstance = await PAMEngine.new()

//     const testTerms = await getTerms()
//     this.contractTerms = testTerms['10001']
//   })

//   it('should yield the initial contract state', async () => {
//     const initialState = await this.PAMEngineInstance.computeInitialState(this.contractTerms, {})

//     assert.isTrue(Number(initialState['lastEventTime']) === Number(this.contractTerms['statusDate']))
//   })

//   it('should yield all events', async () => {
//     const start = this.contractTerms['statusDate'] 
//     const end = this.contractTerms['maturityDate']

//     let protoEventSchedule = await this.PAMEngineInstance.computeProtoEventScheduleSegment(
//       this.contractTerms, 
//       start,
//       end
//     )

//     protoEventSchedule = protoEventSchedule.slice(0, 30)

//     // console.log(protoEventSchedule)
//   })

//   // it('should yield the next next contract state and the contract events', async() => {
//   //   const initialState = await this.PAMEngineInstance.computeInitialState(this.contractTerms, {})
//   //   const timestamp = 1362096000 // 01.03.2013
    
//   //   await this.PAMEngineInstance.computeNextState(this.contractTerms, initialState, timestamp)
//   // })
// })
