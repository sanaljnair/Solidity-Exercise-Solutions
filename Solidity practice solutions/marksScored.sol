pragma solidity 0.5.0;

contract c {
    struct Marks{
        string subject;
        uint score;
    }
    Marks[] public marks;
    
    function addMarks(string memory subject, uint score) public {
        marks.push(Marks({
            subject: subject,
            score: score
        }));
    }
    
    function findPercentage() public view returns(uint){
        // uint countSubject = 0;
        uint totalScore = 0;
        
        for(uint i; i <= marks.length;i++){
            // countSubject ++;
            totalScore = totalScore + marks[i].score;
        }
        
        uint percentage = (totalScore / marks.length) * 100;
        return percentage;
    }
}

// pragma solidity 0.5.0;

// contract C {
// 	struct Marks{
//     	//write your code here
// 	}
// 	Marks[] public marks;
    
// 	//write the function addMarks here
// }
