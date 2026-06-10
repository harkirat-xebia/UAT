/**
 * @author : ALK
 * @date : 30/06/2021
 * @desc : ApplicationException
 */

public with sharing class ApplicationException extends Exception {
  public String message { get; set; }
}