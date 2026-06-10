public class APER09_Task_Management {
  public static Task CreateTask(String Subject, String Status, String WhatId) {
    Task newTask = new Task();
    newTask.WhatId = WhatId;
    newTask.Subject = Subject;
    newTask.Status = Status;
    insert newTask;
    return newTask;
  }

  public static Task CreateTaskForContractWithoutInsert(String Subject, Id OwnerId, Date DueDate, Id WhatId, Id WhoId) {
    Task newTask = new Task();
    newTask.Subject = Subject;
    newTask.OwnerId = OwnerId;
    newTask.ActivityDate = DueDate;
    newTask.WhatId = WhatId;
    newTask.WhoId = WhoId;
    return newTask;
  }

  public static Task CreateTaskForLeadUpdate(String Subject, Id OwnerId, Date DueDate, Id WhoId) {
    Task newTask = new Task();
    newTask.Subject = Subject;
    newTask.OwnerId = OwnerId;
    newTask.ActivityDate = DueDate;
    newTask.WhoId = WhoId;
    return newTask;
  }
  public static Task CreateTaskForLeadCreation(String Subject, Id OwnerId, Date DueDate, Id WhatId) {
    Task newTask = new Task();
    newTask.Subject = Subject;
    newTask.OwnerId = OwnerId;
    newTask.ActivityDate = DueDate;
    newTask.WhatId = WhatId;
    return newTask;
  }
}