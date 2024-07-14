using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Remanufacturing.Messages;
using Remanufacturing.OrderNextCore.Services;
using Remanufacturing.Responses;
using System.Text.Json;

// Comment to cause a change

namespace Remanufacturing.OrderNextCore.Functions;

public class GetNextCore(ILogger<GetNextCore> logger, GetNextCoreServices getNextCoreServices)
{

	private readonly ILogger<GetNextCore> _logger = logger;
	private readonly GetNextCoreServices _getNextCoreServices = getNextCoreServices;

	[Function("GetNextCore")]
	public async Task<IActionResult> RunAsync([HttpTrigger(AuthorizationLevel.Function, "post")] HttpRequest request)
	{
		string requestBody = await new StreamReader(request.Body).ReadToEndAsync();
		OrderNextCoreMessage? nextCoreRequestMessage = JsonSerializer.Deserialize<OrderNextCoreMessage>(requestBody);
		if (nextCoreRequestMessage is not null)
		{
			_logger.LogInformation("Get next core for Pod '{podId}'", nextCoreRequestMessage.PodId);
			IResponse response = await _getNextCoreServices.RequestNextCoreInformationAsync(nextCoreRequestMessage, request.HttpContext.TraceIdentifier);
			return new ObjectResult(response) { StatusCode = (int)response.Status };
		}
		else
		{
			_logger.LogWarning("Invalid request body.");
			return new BadRequestObjectResult("Invalid request body.");
		}
	}

}