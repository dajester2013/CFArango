/*
 * The MIT License (MIT)
 * Copyright (c) 2016 Jesse Shaffer
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

component extends=AbstractAPI {

	public function getDatabaseVersion() {
		return Driver.executeAdminRequest("database/target-version", "", "GET").data;
	}

	public function execute(required string program) {
		return Driver.executeAdminRequest("execute?returnAsJSON=true", program, "POST").data;
	}

	public function readLogs(level=3, includeLower=true, startId, size, offset, search, sort) {
		if (includeLower) {
			arguments.upto=level;
			structDelete(arguments,"level");
		}
		structDelete(arguments,"includeLower");

		if (!isNull(startId)) {
			arguments.start = startId;
			structDelete(arguments,"startId");
		}

		return Driver.executeAdminRequest("log", arguments, "GET").data;
	}

	public struct function getLogLevels() {
		return Driver.executeAdminRequest("log/level", "", "GET").data;
	}

	public numeric function setLogLevels(struct logLevels) {
		return Driver.executeAdminRequest("log/level", logLevels, "PUT").status.code;
	}

	public boolean function reloadRouting() {
		return Driver.executeAdminRequest("routing/reload", "", "POST").status.code == 200;
	}

	public function getServerId() {
		return Driver.executeAdminRequest("server/id", "", "GET").data;
	}

	public function getServerRole() {
		return Driver.executeAdminRequest("server/role", "", "GET").data;
	}

	public boolean function shutdown() {
		return Driver.executeAdminRequest("shutdown", "", "DELETE").status.code==200;
	}

	public struct function getStatistics() {
		return Driver.executeAdminRequest("statistics", "", "GET").data;
	}

	public struct function getStatisticsDescription() {
		return Driver.executeAdminRequest("statistics-description", "", "GET").data;
	}

	public numeric function getServerTime() {
		return Driver.executeAdminRequest("time", "", "GET").data.time;
	}

	public struct function getClusterEndpoints() {
		return Driver.executeAdminRequest("cluster/endpoints", "", "GET").data.endpoints;
	}

	public struct function scheduleTask(required string name, required string command, required numeric period, numeric offset=0, params={}) {
		return Driver.executeApiRequest("task", arguments, "POST").data;
	}

	public struct function getTasks() {
		return Driver.executeApiRequest("tasks", "", "GET").data;
	}

	public struct function stopTask(required id) {
		return Driver.executeApiRequest("tasks/#id#", "", "DELETE").data.error;
	}

	public struct function getTaskStatus() {
		return Driver.executeApiRequest("tasks/#id#", "", "GET").data;
	}

}